class_name FantasyMonSettings
extends Node

signal changed
signal save_failed

const SAVE_PATH := "user://settings.cfg"
const ACTIONS := ["move_forward", "move_backward", "move_left", "move_right"]
const DEFAULT_KEYS := [KEY_W, KEY_S, KEY_A, KEY_D]

var language: String = "en"
var fullscreen: bool = false
var master_volume: float = 1.0
var bindings: Dictionary = {}
var last_error_key: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_apply_all()


func _load_settings() -> void:
	for index in ACTIONS.size():
		bindings[ACTIONS[index]] = DEFAULT_KEYS[index]
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		last_error_key = "SETTINGS_LOAD_FAILED"
		return
	var stored_language: Variant = config.get_value("general", "language", "en")
	if stored_language is String and stored_language in ["en", "de"]:
		language = stored_language
	var stored_fullscreen: Variant = config.get_value("general", "fullscreen", false)
	if stored_fullscreen is bool:
		fullscreen = stored_fullscreen
	var stored_volume: Variant = config.get_value("audio", "master_volume", 1.0)
	if (stored_volume is float or stored_volume is int) and is_finite(float(stored_volume)):
		master_volume = clampf(float(stored_volume), 0.0, 1.0)
	var candidate: Dictionary = {}
	for action in ACTIONS:
		var key: Variant = config.get_value("controls", action, bindings[action])
		if not key is int or not _valid_key(key) or key in candidate.values():
			return # Invalid/duplicate key sets fall back to the complete WASD set.
		candidate[action] = key
	bindings = candidate


func _apply_all() -> void:
	TranslationServer.set_locale(language)
	for action in ACTIONS:
		_apply_binding(action)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	AudioServer.set_bus_volume_linear(0, master_volume)
	AudioServer.set_bus_mute(0, is_zero_approx(master_volume))


func _apply_binding(action: String) -> void:
	Input.action_release(action)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.device = -1
	event.physical_keycode = bindings[action]
	InputMap.action_add_event(action, event)


func set_language(value: String) -> void:
	if value not in ["en", "de"]:
		return
	language = value
	TranslationServer.set_locale(language)
	_commit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_commit()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_linear(0, master_volume)
	AudioServer.set_bus_mute(0, is_zero_approx(master_volume))
	_commit()


func bind_key(action: String, key: int) -> String:
	if action not in ACTIONS or not _valid_key(key):
		return "KEY_RESERVED"
	for other in ACTIONS:
		if other != action and bindings[other] == key:
			return "KEY_IN_USE"
	bindings[action] = key
	_apply_binding(action)
	_commit()
	return ""


func _valid_key(key: int) -> bool:
	return key > 0 and key <= 0x7fffff and key not in [
		KEY_ESCAPE, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK, KEY_NUMLOCK
	]


func key_label(action: String) -> String:
	var key: int = bindings[action]
	var names := {
		KEY_SPACE: "KEY_SPACE", KEY_UP: "KEY_UP", KEY_DOWN: "KEY_DOWN",
		KEY_LEFT: "KEY_LEFT", KEY_RIGHT: "KEY_RIGHT", KEY_ENTER: "KEY_ENTER",
		KEY_TAB: "KEY_TAB", KEY_BACKSPACE: "KEY_BACKSPACE", KEY_DELETE: "KEY_DELETE",
		KEY_HOME: "KEY_HOME", KEY_END: "KEY_END", KEY_PAGEUP: "KEY_PAGEUP",
		KEY_PAGEDOWN: "KEY_PAGEDOWN", KEY_INSERT: "KEY_INSERT"
	}
	return tr(names[key]) if names.has(key) else OS.get_keycode_string(key)


func _commit() -> void:
	var config := ConfigFile.new()
	config.set_value("general", "language", language)
	config.set_value("general", "fullscreen", fullscreen)
	config.set_value("audio", "master_volume", master_volume)
	for action in ACTIONS:
		config.set_value("controls", action, bindings[action])
	last_error_key = "" if config.save(SAVE_PATH) == OK else "SETTINGS_SAVE_FAILED"
	changed.emit()
	if not last_error_key.is_empty():
		save_failed.emit()

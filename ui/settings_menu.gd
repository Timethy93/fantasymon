class_name FantasyMonSettingsMenu
extends CanvasLayer

@onready var settings: FantasyMonSettings = get_node("/root/GameSettings")
@onready var root: Control = %Root
@onready var panel: PanelContainer = %Panel
@onready var tabs: TabContainer = %Tabs
@onready var language_option: OptionButton = %Language
@onready var display_option: OptionButton = %DisplayMode
@onready var volume: HSlider = %Volume
@onready var status: Label = %Status

var _capture_action: String = ""
var _buttons: Dictionary = {}
var _syncing: bool = false


func _ready() -> void:
	_buttons = {
		"move_forward": %Forward, "move_backward": %Backward,
		"move_left": %Left, "move_right": %Right
	}
	language_option.add_item("LANGUAGE_EN")
	language_option.add_item("LANGUAGE_DE")
	display_option.add_item("MODE_WINDOWED")
	display_option.add_item("MODE_FULLSCREEN")
	language_option.item_selected.connect(_language_selected)
	display_option.item_selected.connect(_display_selected)
	volume.value_changed.connect(_volume_changed)
	for action in _buttons:
		_buttons[action].pressed.connect(_begin_capture.bind(action))
	%Close.pressed.connect(close_menu)
	settings.changed.connect(_sync)
	settings.save_failed.connect(_show_save_error)
	get_node("/root/SceneManager").travel_failed.connect(_show_notice)
	root.resized.connect(_resize_panel)
	_translate_tabs()
	_sync()
	_resize_panel()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_translate_tabs()


func _translate_tabs() -> void:
	for index in 3:
		tabs.set_tab_title(index, tr(["TAB_GENERAL", "TAB_CONTROLS", "TAB_AUDIO"][index]))


func _resize_panel() -> void:
	var available := root.size
	# Counter the project's canvas stretch in small native windows.
	var ui_scale := clampf(1152.0 / float(maxi(1, get_window().size.x)), 1.0, 1.8)
	root.theme.default_font_size = roundi(18.0 * ui_scale)
	$Root/Panel/Margin/Content/Title.add_theme_font_size_override("font_size", roundi(30.0 * ui_scale))
	$Root/Panel/Margin/Content/Hint.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
	for control in [language_option, display_option, volume, %Forward, %Backward, %Left, %Right]:
		control.custom_minimum_size = Vector2(160.0, 42.0) * ui_scale
	%Close.custom_minimum_size.y = 42.0 * ui_scale
	panel.size = Vector2(minf(680.0 * ui_scale, available.x - 24.0), minf(530.0 * ui_scale, available.y - 24.0))
	panel.position = (available - panel.size) * 0.5


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not _capture_action.is_empty():
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE:
			_cancel_capture()
			return
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed:
			status.text = "KEY_RESERVED"
			return
		var error_key := settings.bind_key(
			_capture_action, event.physical_keycode if event.physical_keycode else event.keycode
		)
		if error_key.is_empty():
			_cancel_capture()
		else:
			status.text = error_key
		return
	if event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if root.visible:
			close_menu()
		else:
			open_menu()


func open_menu() -> void:
	if root.visible or get_tree().paused:
		return
	if get_node("/root/SceneManager").transition_in_progress:
		return
	for action in settings.ACTIONS:
		Input.action_release(action)
	get_tree().paused = true
	root.show()
	_sync()
	_resize_panel()
	tabs.current_tab = 0
	language_option.grab_focus()


func close_menu() -> void:
	if not root.visible:
		return
	_capture_action = ""
	root.hide()
	for action in settings.ACTIONS:
		Input.action_release(action)
	get_tree().paused = false


func _begin_capture(action: String) -> void:
	_capture_action = action
	status.text = "PRESS_KEY"


func _cancel_capture() -> void:
	var previous := _capture_action
	_capture_action = ""
	_sync()
	if _buttons.has(previous):
		_buttons[previous].grab_focus()


func _sync() -> void:
	_syncing = true
	language_option.select(0 if settings.language == "en" else 1)
	display_option.select(1 if settings.fullscreen else 0)
	volume.value = settings.master_volume * 100.0
	%VolumeValue.text = "%d%%" % roundi(settings.master_volume * 100.0)
	for action in _buttons:
		_buttons[action].text = settings.key_label(action)
	status.text = settings.last_error_key if not settings.last_error_key.is_empty() else "SETTINGS_SAVED"
	_syncing = false


func _language_selected(index: int) -> void:
	if not _syncing:
		settings.set_language("en" if index == 0 else "de")


func _display_selected(index: int) -> void:
	if not _syncing:
		settings.set_fullscreen(index == 1)


func _volume_changed(value: float) -> void:
	if not _syncing:
		settings.set_master_volume(value / 100.0)


func _show_save_error() -> void:
	status.text = settings.last_error_key


func _show_notice(message_key: String) -> void:
	%Notice.text = message_key
	%Notice.show()
	await get_tree().create_timer(4.0, true).timeout
	%Notice.hide()

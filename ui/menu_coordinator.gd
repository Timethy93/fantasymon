extends Node

signal menu_changed(id: StringName)
var _menus: Dictionary = {}
var _active: StringName = &""
var _history: Array[StringName] = []
var active_menu: StringName:
	get:
		return _active

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_menu(id: StringName, view: Control, opened: Callable, closed: Callable = Callable()) -> void:
	_menus[id] = {"view": view, "opened": opened, "closed": closed}
	view.hide()

func has_menu(id: StringName) -> bool:
	return _menus.has(id)

func open_menu(id: StringName, remember: bool = false) -> bool:
	if not _menus.has(id) or get_node("/root/SceneManager").transition_in_progress:
		return false
	if get_tree().paused and _active.is_empty():
		return false # Preserve a pause owned by another system.
	if id == _active:
		return true
	if remember and not _active.is_empty():
		_history.append(_active)
	elif not remember:
		_history.clear()
	_hide_active()
	_active = id
	_release_movement()
	get_tree().paused = true
	_menus[id].view.show()
	_menus[id].opened.call()
	menu_changed.emit(_active)
	return true

func close_menu(id: StringName = &"") -> void:
	if _active.is_empty() or (not id.is_empty() and id != _active):
		return
	_hide_active()
	_active = &""
	_history.clear()
	_release_movement()
	get_tree().paused = false
	menu_changed.emit(_active)

func back() -> void:
	if _history.is_empty():
		close_menu()
	else:
		var previous := _history.pop_back() as StringName
		var remaining := _history.duplicate()
		open_menu(previous)
		_history.assign(remaining)

func _hide_active() -> void:
	if _menus.has(_active):
		_menus[_active].view.hide()
		if _menus[_active].closed.is_valid():
			_menus[_active].closed.call()

func _release_movement() -> void:
	for action in get_node("/root/GameSettings").ACTIONS:
		Input.action_release(action)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var settings_menu := get_node_or_null("/root/SettingsMenu")
	if settings_menu != null and settings_menu.is_capturing():
		return
	if event.keycode == KEY_ESCAPE:
		if _active.is_empty():
			open_menu(&"settings")
		else:
			back()
		get_viewport().set_input_as_handled()
		return
	for id in get_node("/root/GameSettings").UI_KEYS:
		if event.keycode == get_node("/root/GameSettings").UI_KEYS[id]:
			if _active == id:
				close_menu(id)
			else:
				open_menu(id)
			get_viewport().set_input_as_handled()
			return

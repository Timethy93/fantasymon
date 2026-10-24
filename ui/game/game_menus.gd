extends CanvasLayer

const InventoryMenu = preload("res://ui/game/inventory_menu.gd")
const CareMenu = preload("res://ui/game/care_menu.gd")
const StatusMenu = preload("res://ui/game/status_menu.gd")
var status_menu: Control
var inventory_menu: Control
var food_menu: Control
var _monster: MonsterInstance
var _root: Control
var _debug_view: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = get_node("/root/SettingsMenu").root.theme
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_menu = InventoryMenu.new()
	inventory_menu.title_key = "MENU_INVENTORY"
	_register(&"inventory", inventory_menu)
	food_menu = InventoryMenu.new()
	food_menu.title_key = "CARE_FEED"
	food_menu.category_filter = &"Food"
	_register(&"food", food_menu)
	var care := CareMenu.new()
	care.title_key = "MENU_CARE"
	_register(&"care", care)
	status_menu = StatusMenu.new()
	status_menu.title_key = "MENU_STATUS"
	_register(&"status", status_menu)
	get_node("/root/CompanionManager").active_monster_changed.connect(_bind_monster)
	_bind_monster()
	# Dynamic load only; dev/* is excluded from the shipping export preset.
	if OS.is_debug_build() and ResourceLoader.exists("res://dev/life_debug_menu.gd"):
		var debug_script: Script = load("res://dev/life_debug_menu.gd")
		var debug_view: Control = debug_script.new()
		debug_view.title_key = "MENU_DEBUG"
		_register(&"debug", debug_view)
		_debug_view = debug_view
		_bind_monster()

func _register(id: StringName, view: Control) -> void:
	_root.add_child(view)
	get_node("/root/Menus").register_menu(id, view, view.opened)

func _bind_monster() -> void:
	for view in [status_menu, _debug_view]:
		if view != null and _monster != null and _monster.changed.is_connected(view.refresh):
			_monster.changed.disconnect(view.refresh)
	_monster = get_node("/root/CompanionManager").active_monster
	if _monster != null:
		for view in [status_menu, _debug_view]:
			if view != null:
				_monster.changed.connect(view.refresh)
	status_menu.refresh()
	if _debug_view != null:
		_debug_view.refresh()

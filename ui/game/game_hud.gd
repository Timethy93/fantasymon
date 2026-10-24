extends CanvasLayer

const MonsterHud = preload("res://ui/game/monster_hud.gd")
const TimeHud = preload("res://ui/game/world_time_hud.gd")
var monster_hud: PanelContainer
var time_hud: PanelContainer
var navigation: HFlowContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = get_node("/root/SettingsMenu").root.theme
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	navigation = HFlowContainer.new()
	root.add_child(navigation)
	navigation.position = Vector2(12, 12)
	for id in [&"inventory", &"care", &"status", &"settings"]:
		var button := Button.new()
		button.name = String(id)
		button.text = "MENU_" + String(id).to_upper() if id != &"settings" else "SETTINGS_TITLE"
		button.tooltip_text = OS.get_keycode_string(get_node("/root/GameSettings").UI_KEYS[id])
		button.pressed.connect(func(): get_node("/root/Menus").open_menu(id))
		navigation.add_child(button)
	if get_node("/root/Menus").has_menu(&"debug"):
		var debug_button := Button.new()
		debug_button.text = "MENU_DEBUG"
		debug_button.pressed.connect(func(): get_node("/root/Menus").open_menu(&"debug"))
		navigation.add_child(debug_button)
	monster_hud = MonsterHud.new()
	root.add_child(monster_hud)
	time_hud = TimeHud.new()
	root.add_child(time_hud)
	root.resized.connect(_layout.bind(root))
	monster_hud.resized.connect(_layout.bind(root))
	time_hud.resized.connect(_layout.bind(root))
	_layout(root)

func _layout(root: Control) -> void:
	navigation.size.x = maxf(200, root.size.x - time_hud.size.x - 40)
	monster_hud.position = root.size - monster_hud.size - Vector2(16, 16)
	time_hud.position = Vector2(root.size.x - time_hud.size.x - 16, 12)

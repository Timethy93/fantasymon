extends Control

@export var title_key: String = ""
var body: VBoxContainer
var panel: PanelContainer
var first_focus: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.01, 0.02, 0.025, 0.75)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var title := Label.new()
	title.text = title_key
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	var close := Button.new()
	close.text = "MENU_BACK"
	close.pressed.connect(func(): get_node("/root/Menus").back())
	content.add_child(close)
	first_focus = scroll
	build_content()
	resized.connect(_resize)
	_resize()

func _resize() -> void:
	if panel == null:
		return
	panel.size = Vector2(minf(680, size.x - 24), minf(540, size.y - 24))
	panel.position = (size - panel.size) * 0.5

func build_content() -> void:
	pass

func opened() -> void:
	refresh()
	_resize()
	first_focus.grab_focus()

func refresh() -> void:
	pass

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()

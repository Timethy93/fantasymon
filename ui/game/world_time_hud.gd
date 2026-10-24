extends PanelContainer

var label: Label

func _ready() -> void:
	label = Label.new()
	add_child(label)
	get_node("/root/WorldTime").changed.connect(refresh)
	get_node("/root/GameSettings").changed.connect(refresh)
	refresh()

func refresh() -> void:
	if label == null:
		return
	var clock := get_node("/root/WorldTime")
	label.text = tr("WORLD_TIME_FORMAT").format({"day": clock.day(), "hour": str(clock.hour()).pad_zeros(2), "minute": str(clock.minute()).pad_zeros(2)})
	visible = get_node("/root/GameSettings").hud_visible[&"time"]

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()

extends PanelContainer

var fields: Dictionary = {}
var _monster: MonsterInstance

func _ready() -> void:
	var content := VBoxContainer.new()
	add_child(content)
	for id in [&"hp", &"mp", &"satiety"]:
		var row := VBoxContainer.new()
		var label := Label.new()
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(210, 10)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		content.add_child(row)
		fields[id] = {"row": row, "label": label, "bar": bar}
	get_node("/root/CompanionManager").active_monster_changed.connect(_bind)
	get_node("/root/GameSettings").changed.connect(refresh)
	_bind()

func _bind() -> void:
	if _monster != null and _monster.changed.is_connected(refresh):
		_monster.changed.disconnect(refresh)
	_monster = get_node("/root/CompanionManager").active_monster
	if _monster != null:
		_monster.changed.connect(refresh)
	refresh()

func refresh() -> void:
	if fields.is_empty():
		return
	var settings := get_node("/root/GameSettings")
	var any_visible := false
	for id in fields:
		var shown: bool = settings.hud_visible[id] and _monster != null
		fields[id].row.visible = shown
		any_visible = any_visible or shown
		if not shown:
			continue
		var maximum: float = 100.0 if id == &"satiety" else float(_monster.stats.get(id))
		var value: float = _monster.satiety if id == &"satiety" else float(_monster.get("current_" + String(id)))
		var label_key := "SATIETY" if id == &"satiety" else "STAT_" + String(id).to_upper()
		fields[id].label.text = "%s: %s / %s" % [tr(label_key), snappedf(value, 0.1), maximum]
		fields[id].bar.max_value = maxf(1, maximum)
		fields[id].bar.value = value
	visible = any_visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		refresh()

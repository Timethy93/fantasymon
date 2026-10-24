extends "res://ui/game/menu_panel.gd"

var values: Label

func build_content() -> void:
	values = Label.new()
	values.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(values)

func refresh() -> void:
	if values == null or not visible:
		return
	var monster: MonsterInstance = get_node("/root/CompanionManager").active_monster
	if monster == null:
		values.text = "FEED_NO_MONSTER"
		return
	var lines: PackedStringArray = [tr(monster.definition.display_name_key)]
	lines.append("%s: %s / %s" % [tr("STAT_HP"), monster.current_hp, monster.stats.hp])
	lines.append("%s: %s / %s" % [tr("STAT_MP"), monster.current_mp, monster.stats.mp])
	for field in MonsterStats.FIELDS:
		var key := "STAT_" + String(field).to_upper()
		if field in [&"hp", &"mp"]:
			key += "_MAX"
		lines.append("%s: %s" % [tr(key), monster.stats.get(field)])
	lines.append("%s: %.1f / 100" % [tr("SATIETY"), monster.satiety])
	if monster.refusing_food:
		lines.append(tr("FEED_REFUSED"))
	# No invented attributes/elements/needs: these are absent in MonsterDefinition.
	values.text = "\n".join(lines)

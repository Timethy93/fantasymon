extends "res://ui/game/menu_panel.gd"

var numbers: Dictionary = {}
var item_choice: OptionButton
var species_choice: OptionButton
var parameters: Label
var history: Label
var inventory_text: Label
var result: Label

func build_content() -> void:
	_heading("DEBUG_DIRECT")
	_number("world_hours", "DEBUG_WORLD_HOURS", 0, 1.0e12 / 3600.0, 8)
	_button("DEBUG_SET_TIME", func():
		get_node("/root/WorldTime").debug_set_seconds(numbers.world_hours.value * 3600)
		refresh())
	_heading("DEBUG_SIMULATE")
	_number("jump_hours", "DEBUG_JUMP_HOURS", 0.01, 10000, 1)
	_button("DEBUG_ADVANCE", func():
		get_node("/root/WorldTime").advance_hours(numbers.jump_hours.value)
		refresh())
	_heading("DEBUG_MONSTER")
	species_choice = OptionButton.new()
	var registry := MonsterRegistry.new()
	for file in ResourceLoader.list_directory(MonsterRegistry.DEFINITIONS_DIRECTORY):
		if file.ends_with(".tres"):
			var definition := registry.get_monster(StringName(file.get_basename()))
			if definition != null:
				species_choice.add_item(tr(definition.display_name_key))
				species_choice.set_item_metadata(species_choice.item_count - 1, definition.monster_id)
	body.add_child(species_choice)
	_button("DEBUG_SELECT_MONSTER", func():
		get_node("/root/CompanionManager").select_species(species_choice.get_item_metadata(species_choice.selected))
		refresh())
	_number("satiety", "SATIETY", 0, 100, 100)
	_number("current_hp", "DEBUG_CURRENT_HP", 0, MonsterStats.TECHNICAL_MAX, 0)
	_number("current_mp", "DEBUG_CURRENT_MP", 0, MonsterStats.TECHNICAL_MAX, 0)
	for field in MonsterStats.FIELDS:
		var key := "STAT_" + String(field).to_upper()
		if field in [&"hp", &"mp"]:
			key += "_MAX"
		_number("stat_" + String(field), key, 1 if field == &"hp" else 0, MonsterStats.TECHNICAL_MAX, 0)
	_button("DEBUG_APPLY_MONSTER", apply_monster)
	parameters = _label()
	_heading("DEBUG_INVENTORY")
	item_choice = OptionButton.new()
	for item in get_node("/root/PlayerInventory").catalog.items:
		item_choice.add_item(tr(item.name_key))
		item_choice.set_item_metadata(item_choice.item_count - 1, item.item_id)
	body.add_child(item_choice)
	_number("quantity", "DEBUG_QUANTITY", 1, 1000000, 1)
	_button("DEBUG_ADD_ITEM", func(): _change_items(true))
	_button("DEBUG_REMOVE_ITEM", func(): _change_items(false))
	_button("DEBUG_FEED", func():
		result.text = String(get_node("/root/PlayerInventory").feed(_item_id()))
		refresh())
	inventory_text = _label()
	_heading("DEBUG_CARE_EVENTS")
	history = _label()
	_button("DEBUG_CLEAR_EVENTS", func():
		var monster: MonsterInstance = get_node("/root/CompanionManager").active_monster
		if monster != null:
			monster.debug_clear_care_events()
		refresh())
	result = _label()
	first_focus = numbers.world_hours.get_line_edit()
	get_node("/root/WorldTime").changed.connect(refresh)
	get_node("/root/PlayerInventory").inventory.changed.connect(refresh)

func _heading(key: String) -> void:
	var label := _label()
	label.text = key
	label.add_theme_font_size_override("font_size", 22)

func _label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)
	return label

func _number(id: String, key: String, minimum: float, maximum: float, initial: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = key
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value := SpinBox.new()
	value.min_value = minimum
	value.max_value = maximum
	value.step = 0.1 if id in ["world_hours", "jump_hours", "satiety"] else 1.0
	value.value = initial
	value.custom_minimum_size.x = 190
	row.add_child(value)
	body.add_child(row)
	numbers[id] = value

func _button(key: String, action: Callable) -> void:
	var button := Button.new()
	button.text = key
	button.pressed.connect(action)
	body.add_child(button)

func _item_id() -> StringName:
	return item_choice.get_item_metadata(item_choice.selected) if item_choice.selected >= 0 else &""

func _change_items(add: bool) -> void:
	var session := get_node("/root/PlayerInventory")
	var count := int(numbers.quantity.value)
	var success: bool = session.inventory.add(session.catalog.get_item(_item_id()), count) if add else session.inventory.remove(_item_id(), count)
	result.text = "DEBUG_DONE" if success else "DEBUG_REJECTED"
	refresh()

func apply_monster() -> void:
	var monster: MonsterInstance = get_node("/root/CompanionManager").active_monster
	if monster == null:
		return
	var values := {}
	for key in numbers:
		values[key] = numbers[key].value
	for field in MonsterStats.FIELDS:
		monster.stats.set(field, int(values["stat_" + String(field)]))
	monster.current_hp = int(values.current_hp)
	monster.current_mp = int(values.current_mp)
	monster.debug_set_satiety(values.satiety)
	refresh()

func refresh() -> void:
	if history == null or not visible:
		return
	var clock := get_node("/root/WorldTime")
	numbers.world_hours.set_value_no_signal(clock.total_seconds / 3600.0)
	var monster: MonsterInstance = get_node("/root/CompanionManager").active_monster
	if monster != null:
		numbers.satiety.set_value_no_signal(monster.satiety)
		numbers.current_hp.set_value_no_signal(monster.current_hp)
		numbers.current_mp.set_value_no_signal(monster.current_mp)
		for field in MonsterStats.FIELDS:
			numbers["stat_" + String(field)].set_value_no_signal(monster.stats.get(field))
		parameters.text = tr("DEBUG_PARAMETERS").format({"id": monster.instance_id, "decay": monster.definition.satiety_decay_rate, "requirement": monster.definition.food_requirement})
		var lines: PackedStringArray = []
		for event in monster.care_events():
			lines.append("%s · %.2f h · %s" % [tr("CARE_EVENT_" + String(event.cause)), event.world_seconds / 3600.0, event.instance_id])
		history.text = "\n".join(lines) if not lines.is_empty() else tr("DEBUG_NO_EVENTS")
	var inventory = get_node("/root/PlayerInventory").inventory
	var lines: PackedStringArray = [tr("DEBUG_SLOTS").format({"used": inventory.stacks().size(), "capacity": inventory.capacity})]
	for stack in inventory.stacks():
		lines.append(tr(stack.item.name_key) + " × " + str(stack.quantity))
	inventory_text.text = "\n".join(lines)
	for index in item_choice.item_count:
		var item: Resource = get_node("/root/PlayerInventory").catalog.get_item(item_choice.get_item_metadata(index))
		item_choice.set_item_text(index, tr(item.name_key))

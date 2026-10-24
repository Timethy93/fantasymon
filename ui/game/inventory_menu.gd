extends "res://ui/game/menu_panel.gd"

@export var category_filter: StringName
var list: ItemList
var details: Label
var result: Label
var use_button: Button
var selected_id: StringName
var quantity: SpinBox
var _last_outcome: Dictionary = {}
var _feeding := false

func build_content() -> void:
	list = ItemList.new()
	list.custom_minimum_size.y = 175
	list.item_selected.connect(_selected)
	body.add_child(list)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(details)
	var quantity_row := HBoxContainer.new()
	var quantity_label := Label.new()
	quantity_label.text = "FEED_QUANTITY"
	quantity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_row.add_child(quantity_label)
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = 1
	quantity.step = 1
	quantity.value = 1
	quantity_row.add_child(quantity)
	body.add_child(quantity_row)
	use_button = Button.new()
	use_button.text = "ITEM_USE"
	use_button.pressed.connect(use_selected)
	body.add_child(use_button)
	result = Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(result)
	first_focus = list
	get_node("/root/PlayerInventory").inventory.changed.connect(refresh)

func opened() -> void:
	quantity.value = 1
	_last_outcome.clear()
	result.text = ""
	super.opened()

func refresh() -> void:
	if list == null:
		return
	list.clear()
	var session := get_node("/root/PlayerInventory")
	for stack in session.inventory.stacks():
		var item: Resource = stack.item
		if not category_filter.is_empty() and item.category != category_filter:
			continue
		var index := list.add_item(tr(item.name_key) + " × " + str(stack.quantity), item.icon)
		list.set_item_metadata(index, item.item_id)
	var chosen := 0
	for index in list.item_count:
		if list.get_item_metadata(index) == selected_id:
			chosen = index
	if list.item_count > 0:
		list.select(chosen)
		_selected(chosen)
	else:
		selected_id = &""
		details.text = "INVENTORY_EMPTY"
		use_button.disabled = true
		quantity.max_value = 1
		quantity.editable = false
	if not _last_outcome.is_empty():
		result.text = tr("FEED_BATCH_OK").format(_last_outcome) if _last_outcome.result == &"FEED_OK" else tr("FEED_BATCH_STOPPED").format({"consumed": _last_outcome.consumed, "requested": _last_outcome.requested, "reason": tr(_last_outcome.result)})

func _selected(index: int) -> void:
	var next_id: StringName = list.get_item_metadata(index)
	if next_id != selected_id:
		quantity.value = 1
	selected_id = next_id
	var item: Resource = get_node("/root/PlayerInventory").catalog.get_item(selected_id)
	details.text = tr(item.name_key) + "\n" + tr(item.description_key)
	use_button.disabled = item.category != &"Food"
	quantity.max_value = maxi(1, get_node("/root/PlayerInventory").inventory.quantity(selected_id))
	quantity.editable = item.category == &"Food"

func use_selected() -> void:
	if selected_id.is_empty() or _feeding:
		return
	_feeding = true
	_last_outcome = get_node("/root/PlayerInventory").feed_many(selected_id, int(quantity.value))
	_feeding = false
	refresh()

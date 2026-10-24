extends "res://ui/game/menu_panel.gd"

@export var category_filter: StringName
var list: ItemList
var details: Label
var result: Label
var use_button: Button
var selected_id: StringName

func build_content() -> void:
	list = ItemList.new()
	list.custom_minimum_size.y = 175
	list.item_selected.connect(_selected)
	body.add_child(list)
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(details)
	use_button = Button.new()
	use_button.text = "ITEM_USE"
	use_button.pressed.connect(use_selected)
	body.add_child(use_button)
	result = Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(result)
	first_focus = list
	get_node("/root/PlayerInventory").inventory.changed.connect(refresh)

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

func _selected(index: int) -> void:
	selected_id = list.get_item_metadata(index)
	var item: Resource = get_node("/root/PlayerInventory").catalog.get_item(selected_id)
	details.text = tr(item.name_key) + "\n" + tr(item.description_key)
	use_button.disabled = item.category != &"Food"

func use_selected() -> void:
	if selected_id.is_empty():
		return
	result.text = String(get_node("/root/PlayerInventory").feed(selected_id))
	refresh()

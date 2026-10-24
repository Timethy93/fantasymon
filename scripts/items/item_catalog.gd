class_name FantasyMonItemCatalog
extends Resource

const Item = preload("res://scripts/items/item_definition.gd")
@export var items: Array[Resource] = []
@export_range(0, 1000) var inventory_capacity: int = 20
@export var initial_quantities: Dictionary[StringName, int] = {}

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for item in items:
		if not item is Item or not item.is_valid():
			errors.append("Invalid item definition.")
		elif seen.has(item.item_id):
			errors.append("Duplicate item ID: %s" % item.item_id)
		else:
			seen[item.item_id] = true
	for id in initial_quantities:
		if not seen.has(id) or initial_quantities[id] < 0:
			errors.append("Invalid initial inventory entry: %s" % id)
	return errors

func get_item(id: StringName) -> Resource:
	for item in items:
		if item is Item and item.item_id == id:
			return item
	return null

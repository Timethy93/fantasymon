extends Node

signal feeding_finished(result: StringName)
const Inventory = preload("res://scripts/items/inventory.gd")
const Feeding = preload("res://scripts/items/feeding_service.gd")
@export var catalog: Resource = preload("res://data/items/catalog.tres")
var inventory: Inventory
var feeding := Feeding.new()

func _ready() -> void:
	inventory = Inventory.new(catalog.inventory_capacity)
	var errors: PackedStringArray = catalog.validation_errors()
	if not errors.is_empty():
		push_error(str(errors))
		return
	for id in catalog.initial_quantities:
		var count: int = catalog.initial_quantities[id]
		if count > 0 and not inventory.add(catalog.get_item(id), count):
			push_error("Initial inventory exceeds capacity: %s" % id)

func feed(id: StringName) -> StringName:
	var result := feeding.feed(get_node("/root/CompanionManager").active_monster,
		inventory, catalog.get_item(id), get_node("/root/WorldTime").total_seconds)
	feeding_finished.emit(result)
	return result

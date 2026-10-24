class_name FantasyMonItemDefinition
extends Resource

const Effect = preload("res://scripts/items/item_effect.gd")
const MAX_STACK := 1000000 # Technical limit, not balancing.
@export var item_id: StringName
@export var name_key: StringName
@export var description_key: StringName
@export var category: StringName = &"Food"
@export var icon: Texture2D
@export_range(1, MAX_STACK) var max_stack: int = 20
@export var effects: Array[Resource] = []

func is_valid() -> bool:
	var id := String(item_id)
	if id.is_empty() or not id.is_valid_identifier() or id != id.to_lower():
		return false
	if name_key.is_empty() or description_key.is_empty() or category.is_empty() or max_stack < 1 or max_stack > MAX_STACK:
		return false
	for effect in effects:
		if not effect is Effect or not is_finite(effect.value) or effect.value <= 0:
			return false
	return true

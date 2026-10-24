class_name FantasyMonFeedingService
extends RefCounted

const Item = preload("res://scripts/items/item_definition.gd")
const Inventory = preload("res://scripts/items/inventory.gd")
var _busy := false

# Result keys are stable and translated by UI. No world/UI singleton dependency.
func feed(monster: MonsterInstance, inventory: Inventory, item: Resource, at_seconds: float) -> StringName:
	if _busy:
		return &"FEED_BUSY"
	if monster == null or monster.definition == null:
		return &"FEED_NO_MONSTER"
	if not item is Item or not item.is_valid() or item.category != &"Food":
		return &"FEED_NOT_FOOD"
	if inventory == null or inventory.quantity(item.item_id) < 1:
		return &"FEED_NO_ITEM"
	if monster.refusing_food:
		return &"FEED_REFUSED"
	var gain := 0.0
	for effect in item.effects:
		if effect.kind != &"satiety":
			return &"FEED_UNSUPPORTED"
		gain += effect.value
	var requirement := monster.definition.food_requirement
	if requirement <= 0 or not is_finite(requirement) or not is_finite(gain / requirement) or gain <= 0 or not is_finite(at_seconds):
		return &"FEED_UNSUPPORTED"
	var effective_gain := gain / requirement
	if effective_gain <= 0:
		return &"FEED_UNSUPPORTED" # Finite division may still underflow to zero.
	_busy = true
	var accepted := inventory.consume_if(item.item_id, 1,
		monster.receive_food.bind(effective_gain, at_seconds))
	_busy = false
	return &"FEED_OK" if accepted else &"FEED_REFUSED"

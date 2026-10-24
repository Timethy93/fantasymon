class_name FantasyMonFeedingService
extends RefCounted

const Item = preload("res://scripts/items/item_definition.gd")
const Inventory = preload("res://scripts/items/inventory.gd")
var _busy := false
var _batch_busy := false

# Each successful piece commits independently; the first failure stops the batch.
func feed_many(monster: MonsterInstance, inventory: Inventory, item: Resource, at_seconds: float, count: int) -> Dictionary:
	var outcome := {"requested": count, "consumed": 0, "result": &"FEED_OK"}
	if _busy or _batch_busy:
		outcome.result = &"FEED_BUSY"
		return outcome
	if count < 1:
		outcome.result = &"FEED_INVALID_QUANTITY"
		return outcome
	if not item is Item or not item.is_valid() or item.category != &"Food":
		outcome.result = &"FEED_NOT_FOOD"
		return outcome
	if inventory == null or inventory.quantity(item.item_id) < count:
		outcome.result = &"FEED_NO_ITEM"
		return outcome
	_batch_busy = true
	for piece in count:
		# feed checks current stock and all monster rules again for every piece.
		outcome.result = feed(monster, inventory, item, at_seconds)
		if outcome.result != &"FEED_OK":
			break
		outcome.consumed += 1
	_batch_busy = false
	return outcome

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

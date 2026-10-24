class_name FantasyMonInventory
extends RefCounted

signal changed
const Item = preload("res://scripts/items/item_definition.gd")
const MAX_QUANTITY := 1000000
var _capacity: int
var _stacks: Array[Dictionary] = []
var capacity: int:
	get:
		return _capacity

func _init(slot_capacity: int = 20) -> void:
	_capacity = clampi(slot_capacity, 0, 1000)

func set_capacity(value: int) -> bool:
	if value < _stacks.size() or value < 0 or value > 1000:
		return false
	_capacity = value
	changed.emit()
	return true

func stacks() -> Array[Dictionary]:
	return _stacks.duplicate(true)

func quantity(id: StringName) -> int:
	var total := 0
	for stack in _stacks:
		if stack.item.item_id == id:
			total += stack.quantity
	return total

func can_add(item: Resource, count: int) -> bool:
	if not item is Item or not item.is_valid() or count <= 0 or count > MAX_QUANTITY:
		return false
	var remaining := count
	for stack in _stacks:
		if stack.item.item_id == item.item_id:
			# One canonical definition per ID; reject conflicting external definitions.
			if stack.item != item:
				return false
			remaining -= item.max_stack - stack.quantity
	var required := ceili(float(maxi(0, remaining)) / item.max_stack)
	return required <= _capacity - _stacks.size()

func add(item: Resource, count: int) -> bool:
	if not can_add(item, count):
		return false
	var remaining := count
	for stack in _stacks:
		if stack.item == item:
			var take := mini(remaining, item.max_stack - int(stack.quantity))
			stack.quantity += take
			remaining -= take
	while remaining > 0:
		var take := mini(remaining, item.max_stack)
		_stacks.append({"item": item, "quantity": take})
		remaining -= take
	changed.emit()
	return true

func remove(id: StringName, count: int, notify: bool = true) -> bool:
	if count <= 0 or count > MAX_QUANTITY or quantity(id) < count:
		return false
	var remaining := count
	for index in range(_stacks.size() - 1, -1, -1):
		var stack := _stacks[index]
		if stack.item.item_id == id:
			var take := mini(remaining, int(stack.quantity))
			stack.quantity -= take
			remaining -= take
			if stack.quantity == 0:
				_stacks.remove_at(index)
			if remaining == 0:
				break
	if notify:
		changed.emit()
	return true

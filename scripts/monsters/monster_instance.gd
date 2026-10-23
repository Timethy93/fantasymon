class_name MonsterInstance
extends RefCounted

var _instance_id: StringName
var _definition: MonsterDefinition
var _stats: MonsterStats

# Public identity has no writable backing data.
var instance_id: StringName:
	get:
		return _instance_id
var definition: MonsterDefinition:
	get:
		return _definition

# Assignments copy as well, so callers cannot accidentally share mutable stats.
var stats: MonsterStats:
	get:
		return _stats
	set(value):
		if value == null:
			return
		if _stats != null:
			_stats.changed.disconnect(_on_stats_changed)
		_stats = value.copy()
		_stats.changed.connect(_on_stats_changed)
		_on_stats_changed()

var current_hp: int = 0:
	set(value):
		current_hp = clampi(value, 0, _stats.hp if _stats != null else 0)
var current_mp: int = 0:
	set(value):
		current_mp = clampi(value, 0, _stats.mp if _stats != null else 0)


# Use this factory for validated creation. No model nodes or gameplay services.
static func create(source: MonsterDefinition) -> MonsterInstance:
	if source == null or not source.validation_errors().is_empty():
		return null
	return MonsterInstance.new(source)


func _init(source: MonsterDefinition) -> void:
	_instance_id = StringName(Crypto.new().generate_random_bytes(16).hex_encode())
	_definition = source
	if source != null and source.base_stats != null:
		stats = source.base_stats
		current_hp = stats.hp
		current_mp = stats.mp


func _on_stats_changed() -> void:
	# Lowering maxima clamps vitals; increasing maxima does NOT heal/refill.
	current_hp = current_hp
	current_mp = current_mp

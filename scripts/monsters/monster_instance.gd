class_name MonsterInstance
extends RefCounted

signal changed
signal care_event_recorded(event: RefCounted)
const CareEvent = preload("res://scripts/life/care_event.gd")
const SATIETY_FULL := 80.0
const SATIETY_MAX := 100.0

var _satiety: float = 100.0
var _refusing_food := false
var _starvation_recorded := false
var _care_events: Array[RefCounted] = []
var satiety: float:
	get:
		return _satiety
	set(value):
		debug_set_satiety(value)
var refusing_food: bool:
	get:
		return _refusing_food

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
		changed.emit()
var current_mp: int = 0:
	set(value):
		current_mp = clampi(value, 0, _stats.mp if _stats != null else 0)
		changed.emit()


# Use this factory for validated creation. No model nodes or gameplay services.
static func create(source: MonsterDefinition) -> MonsterInstance:
	if source == null or not source.validation_errors().is_empty():
		return null
	return MonsterInstance.new(source)


func _init(source: MonsterDefinition) -> void:
	_instance_id = StringName(Crypto.new().generate_random_bytes(16).hex_encode())
	_definition = source
	if source != null:
		_satiety = source.initial_satiety
	if source != null and source.base_stats != null:
		stats = source.base_stats
		current_hp = stats.hp
		current_mp = stats.mp


func _on_stats_changed() -> void:
	# Lowering maxima clamps vitals; increasing maxima does NOT heal/refill.
	current_hp = current_hp
	current_mp = current_mp
	changed.emit()

func debug_set_satiety(value: float) -> void:
	if not is_finite(value):
		return
	_satiety = clampf(value, 0.0, SATIETY_MAX)
	if _satiety > 0.0:
		_starvation_recorded = false
	if _satiety < SATIETY_FULL:
		_refusing_food = false
	changed.emit()

func care_events() -> Array[RefCounted]:
	return _care_events.duplicate()

func debug_clear_care_events() -> void:
	_care_events.clear() # Do not re-arm an ongoing starvation phase.
	changed.emit()

func _record_care(cause: StringName, at_seconds: float) -> void:
	var event := CareEvent.new(cause, at_seconds, instance_id)
	_care_events.append(event)
	care_event_recorded.emit(event)

func advance_care(from_seconds: float, to_seconds: float) -> void:
	if not is_finite(from_seconds) or not is_finite(to_seconds) or to_seconds <= from_seconds:
		return
	var rate := definition.satiety_decay_rate
	if not is_finite(rate) or rate <= 0:
		return
	var before := _satiety
	_satiety = maxf(0.0, before - rate * (to_seconds - from_seconds) / 3600.0)
	if before > 0 and _satiety == 0 and not _starvation_recorded:
		_starvation_recorded = true
		_record_care(CareEvent.STARVATION, from_seconds + before / rate * 3600.0)
	if _satiety < SATIETY_FULL:
		_refusing_food = false
	if _satiety != before:
		changed.emit()

# Model operation; inventory ownership/consumption is handled by FeedingService.
func receive_food(effective_gain: float, at_seconds: float) -> bool:
	if refusing_food or not is_finite(effective_gain) or effective_gain <= 0 or not is_finite(at_seconds):
		return false
	var calculated := _satiety + effective_gain
	_satiety = minf(SATIETY_MAX, calculated)
	_starvation_recorded = false
	if calculated > SATIETY_MAX:
		_refusing_food = true
		_record_care(CareEvent.OVERFEEDING, at_seconds)
	changed.emit()
	return true

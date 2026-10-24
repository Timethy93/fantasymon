class_name FantasyMonWorldClock
extends Node

signal advanced(from_seconds: float, to_seconds: float)
signal changed

const SECONDS_PER_HOUR := 3600.0
const SECONDS_PER_DAY := 86400.0
const MAX_WORLD_SECONDS := 1.0e12 # Technical bound, not a lifespan rule.

@export var game_seconds_per_real_second: float = 60.0
@export var region_time_factor: float = 1.0
@export var initial_world_seconds: float = 28800.0 # MVP: day 1, 08:00.
var _seconds: float = 28800.0
var total_seconds: float:
	get:
		return _seconds

func _ready() -> void:
	_seconds = clampf(initial_world_seconds, 0.0, MAX_WORLD_SECONDS)

func _physics_process(delta: float) -> void:
	if get_tree().paused or get_tree().current_scene == null:
		return
	var scenes := get_node_or_null("/root/SceneManager")
	if scenes != null and scenes.transition_in_progress:
		return
	advance_seconds(delta * game_seconds_per_real_second * region_time_factor)

func advance_seconds(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0.0 or _seconds + amount > MAX_WORLD_SECONDS:
		return false
	var before := _seconds
	_seconds += amount
	advanced.emit(before, _seconds)
	changed.emit()
	return true

func advance_hours(hours: float) -> bool:
	return advance_seconds(hours * SECONDS_PER_HOUR)

# Direct test-state manipulation: deliberately no simulation/advanced signal.
func debug_set_seconds(value: float) -> bool:
	if not is_finite(value) or value < 0.0 or value > MAX_WORLD_SECONDS:
		return false
	_seconds = value
	changed.emit()
	return true

func day() -> int:
	return floori(_seconds / SECONDS_PER_DAY) + 1

func hour() -> int:
	return floori(fmod(_seconds, SECONDS_PER_DAY) / SECONDS_PER_HOUR)

func minute() -> int:
	return floori(fmod(_seconds, SECONDS_PER_HOUR) / 60.0)

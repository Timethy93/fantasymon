class_name MonsterStats
extends Resource

# Temporary technical safety bounds, NOT game balance or save-format limits.
const TECHNICAL_MIN := 0
const TECHNICAL_MAX := 1_000_000
const HP_MIN := 1
const FIELDS: Array[StringName] = [&"hp", &"mp", &"atk", &"defense", &"speed", &"brain"]

@export_range(HP_MIN, TECHNICAL_MAX, 1) var hp: int = HP_MIN:
	set(value):
		hp = clampi(value, HP_MIN, TECHNICAL_MAX)
		emit_changed()
@export_range(TECHNICAL_MIN, TECHNICAL_MAX, 1) var mp: int = 0:
	set(value):
		mp = clampi(value, TECHNICAL_MIN, TECHNICAL_MAX)
		emit_changed()
@export_range(TECHNICAL_MIN, TECHNICAL_MAX, 1) var atk: int = 0:
	set(value):
		atk = clampi(value, TECHNICAL_MIN, TECHNICAL_MAX)
		emit_changed()
@export_range(TECHNICAL_MIN, TECHNICAL_MAX, 1) var defense: int = 0:
	set(value):
		defense = clampi(value, TECHNICAL_MIN, TECHNICAL_MAX)
		emit_changed()
@export_range(TECHNICAL_MIN, TECHNICAL_MAX, 1) var speed: int = 0:
	set(value):
		speed = clampi(value, TECHNICAL_MIN, TECHNICAL_MAX)
		emit_changed()
@export_range(TECHNICAL_MIN, TECHNICAL_MAX, 1) var brain: int = 0:
	set(value):
		brain = clampi(value, TECHNICAL_MIN, TECHNICAL_MAX)
		emit_changed()


func copy() -> MonsterStats:
	var result := MonsterStats.new()
	for field in FIELDS:
		result.set(field, get(field))
	return result


# Generic data mutation; no training costs, rewards, time or gameplay rules.
# Clamp the delta BEFORE addition to avoid int64 overflow with extreme inputs.
func adjust(field: StringName, delta: int) -> bool:
	if field not in FIELDS:
		return false
	set(field, int(get(field)) + clampi(delta, -TECHNICAL_MAX, TECHNICAL_MAX))
	return true

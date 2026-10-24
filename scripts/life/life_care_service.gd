extends Node

func _ready() -> void:
	get_node("/root/WorldTime").advanced.connect(_advance)

func _advance(from_seconds: float, to_seconds: float) -> void:
	var monster: MonsterInstance = get_node("/root/CompanionManager").active_monster
	if monster != null:
		monster.advance_care(from_seconds, to_seconds)

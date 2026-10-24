class_name MonsterCareEvent
extends RefCounted

const STARVATION: StringName = &"STARVATION"
const OVERFEEDING: StringName = &"OVERFEEDING"

var _cause: StringName
var _world_seconds: float
var _instance_id: StringName
var cause: StringName:
	get:
		return _cause
var world_seconds: float:
	get:
		return _world_seconds
var instance_id: StringName:
	get:
		return _instance_id

func _init(reason: StringName, timestamp: float, owner_id: StringName) -> void:
	_cause = reason
	_world_seconds = timestamp
	_instance_id = owner_id

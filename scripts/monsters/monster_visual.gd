class_name MonsterVisual
extends Node3D

var logical_state: StringName = &"idle"
var model: Node3D
var _definition: MonsterDefinition
var _animator: AnimationPlayer


func set_definition(definition: MonsterDefinition) -> bool:
	if is_instance_valid(model):
		remove_child(model)
		model.queue_free()
	model = null
	_animator = null
	_definition = definition
	if definition == null or definition.visual_scene == null:
		return false
	var instance := definition.visual_scene.instantiate()
	if not instance is Node3D:
		instance.free()
		return false
	model = instance
	add_child(model)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_animator = players[0] as AnimationPlayer
	logical_state = &""
	set_walking(false)
	return true


func set_walking(walking: bool) -> void:
	var next: StringName = &"walk" if walking else &"idle"
	if logical_state == next:
		return
	logical_state = next
	if _animator == null:
		return
	var animation := _definition.walk_animation if walking else _definition.idle_animation
	if _animator.has_animation(animation):
		_animator.play(animation)
	elif _animator.has_animation(_definition.idle_animation):
		_animator.play(_definition.idle_animation)
	else:
		_animator.stop()

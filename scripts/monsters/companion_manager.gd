class_name FantasyMonCompanionManager
extends Node

signal active_monster_changed

@export var default_monster_id: StringName = &"drako"

var _registry := MonsterRegistry.new()
var _active_monster: MonsterInstance
var _actor: CompanionFollower
var last_error: String = ""

var active_monster: MonsterInstance:
	get:
		return _active_monster


func _ready() -> void:
	get_tree().scene_changed.connect(ensure_companion)
	call_deferred("ensure_companion")


func get_actor() -> CompanionFollower:
	return _actor if is_instance_valid(_actor) else null


func select_species(id: StringName) -> bool:
	last_error = ""
	if _active_monster != null and _active_monster.definition.monster_id == id:
		ensure_companion()
		return true
	var definition := _registry.get_monster(id)
	if definition == null:
		last_error = _registry.last_error
		return false
	return set_active_monster(MonsterInstance.create(definition))


func set_active_monster(data: MonsterInstance) -> bool:
	if data == null or data.definition == null or not data.definition.validation_errors().is_empty():
		last_error = "Invalid companion data."
		return false
	last_error = ""
	if data != _active_monster:
		_remove_actor()
		_active_monster = data
		active_monster_changed.emit()
	ensure_companion()
	return true


func _remove_actor() -> void:
	if is_instance_valid(_actor):
		_actor.get_parent().remove_child(_actor)
		_actor.queue_free()
	_actor = null


func ensure_companion() -> void:
	# A scene_changed listener may run before SceneManager places the player.
	# Wait for physics registration and recheck after the deferred work.
	var scene := get_tree().current_scene
	if scene == null:
		return
	await get_tree().physics_frame
	await get_tree().process_frame
	if not is_instance_valid(scene) or scene != get_tree().current_scene:
		return
	var player := scene.get_node_or_null("Player") as CharacterBody3D
	if player == null or not player.is_in_group("player"):
		return
	if is_instance_valid(_actor) and _actor.get_parent() == scene:
		return
	if _active_monster == null:
		var definition := _registry.get_monster(default_monster_id)
		_active_monster = MonsterInstance.create(definition)
		if _active_monster == null:
			last_error = "Invalid default companion: %s" % default_monster_id
			push_error(last_error)
			return
		active_monster_changed.emit()
	_remove_actor()
	var packed := load("res://scenes/monsters/companion.tscn") as PackedScene
	var actor := packed.instantiate() as CompanionFollower
	var shape := actor.get_node("CollisionShape3D").shape as Shape3D
	var spawn: Variant = _find_spawn(player, shape)
	if spawn == null:
		actor.free()
		last_error = "No safe companion spawn near the player."
		push_error(last_error)
		return
	_actor = actor
	actor.configure(_active_monster, player)
	scene.add_child(actor)
	actor.global_position = spawn


func _find_spawn(player: CharacterBody3D, shape: Shape3D) -> Variant:
	var space := player.get_world_3d().direct_space_state
	var feet := player.global_position - Vector3(0, 0.9, 0)
	# Test a small ring; never spawn beyond a boundary, inside a rock or on its roof.
	for offset in [Vector3(0, 0, 1.4), Vector3(-1.4, 0, 0), Vector3(1.4, 0, 0),
			Vector3(0, 0, -1.4), Vector3(-1, 0, 1), Vector3(1, 0, 1),
			Vector3(-1, 0, -1), Vector3(1, 0, -1)]:
		var candidate: Vector3 = feet + offset
		var ray := PhysicsRayQueryParameters3D.create(
			candidate + Vector3.UP * 3.0, candidate - Vector3.UP * 3.0, 1, [player.get_rid()]
		)
		var ground := space.intersect_ray(ray)
		if ground.is_empty() or absf(ground.position.y - feet.y) > 0.5:
			continue
		candidate.y = ground.position.y + 0.03
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, candidate + Vector3.UP * 0.6)
		query.collision_mask = 1
		query.exclude = [player.get_rid()]
		if not space.intersect_shape(query, 1).is_empty():
			continue
		var sight := PhysicsRayQueryParameters3D.create(
			candidate + Vector3.UP * 0.6, feet + Vector3.UP * 0.6, 1, [player.get_rid()]
		)
		if space.intersect_ray(sight).is_empty():
			return candidate
	return null

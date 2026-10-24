extends SceneTree

var _checks := 0
var _failures := 0
var _manager: FantasyMonCompanionManager


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)


func _ticks(count: int) -> void:
	for frame in count:
		await physics_frame


func _run() -> void:
	_manager = root.get_node("CompanionManager")
	change_scene_to_file("res://forest_clearing.tscn")
	await scene_changed
	await _ticks(45)
	var actor := _manager.get_actor()
	_check(actor != null, "Default companion spawned")
	if actor == null:
		quit(1)
		return
	_check(actor.monster == _manager.active_monster, "World body references central data")
	_check(actor.monster.definition.monster_id == &"drako", "Existing Drako definition is default")
	_check(actor.visual.model != null, "Model loaded through definition")
	_check(actor.is_on_floor(), "Spawn has valid floor")
	_check(not actor.is_in_group("player") and actor.collision_layer == 2, "Companion cannot act as player")
	for repeat in 10:
		_manager.ensure_companion()
	await _ticks(15)
	_check(get_nodes_in_group("companion").size() == 1, "Repeated attachment creates no duplicates")
	var initial := actor.global_position
	Input.action_press("move_forward")
	await _ticks(30)
	_check(actor.visual.logical_state == &"walk", "Moving body requests walk without clips")
	Input.action_release("move_forward")
	await _ticks(10)
	_check(actor.global_position.z < initial.z - 0.3, "Companion follows moving player")
	await _ticks(120)
	_check(actor.velocity.length() < 0.1, "Companion stops near player")
	_check(actor.visual.logical_state == &"idle", "Stopped body requests idle")
	var player := current_scene.get_node("Player") as CharacterBody3D
	var separation := Vector2(actor.position.x - player.position.x, actor.position.z - player.position.z).length()
	_check(separation < actor.follow_distance + actor.restart_margin + 0.1 and separation > 0.6, "Follow distance respected")

	var data := _manager.active_monster
	var id := data.instance_id
	data.stats.atk = 45
	data.current_hp = 12
	data.current_mp = 7
	var old_actor := actor.get_instance_id()
	_check(not _manager.select_species(&"unknown_monster"), "Invalid species is controlled")
	_check(_manager.active_monster == data and _manager.get_actor() == actor, "Invalid selection preserves current companion")
	_manager.select_species(&"drako")
	await _ticks(5)
	_check(_manager.active_monster == data, "Selecting same species is idempotent")

	# Walk the existing exit route; the companion must not trigger it itself.
	player.position = Vector3(0, 0.95, 0)
	_check(await _walk_to("move_forward", "res://forest_path.tscn"), "A to B")
	actor = _manager.get_actor()
	_check(actor != null and actor.get_instance_id() != old_actor, "New scene creates new body")
	_check(_manager.active_monster == data and actor.monster == data and data.instance_id == id, "Exact MonsterInstance survives")
	_check(data.stats.atk == 45 and data.current_hp == 12 and data.current_mp == 7, "Stats and vitals survive")
	_check(get_nodes_in_group("companion").size() == 1, "Single companion in B")
	_check(actor.is_on_floor(), "Safe B entry spawn")
	_check(await _walk_to("move_backward", "res://forest_clearing.tscn"), "B to A")
	_check(_manager.active_monster == data and data.stats.atk == 45, "Data survives round trip")

	_check(_manager.select_species(&"slimo"), "Second species selected")
	await _ticks(30)
	actor = _manager.get_actor()
	_check(actor.monster.definition.monster_id == &"slimo", "Generic controller uses Slimo")
	_check(actor.visual.model.name == "SlimoVisual", "Second species uses its own model")
	_check(get_nodes_in_group("companion").size() == 1, "Switching species removes previous body")
	_check(actor.visual.logical_state == &"idle", "No AnimationPlayer is harmless")

	var previous_rate := Engine.physics_ticks_per_second
	var at_30 := await _follow_at_rate(30)
	var at_60 := await _follow_at_rate(60)
	var at_120 := await _follow_at_rate(120)
	Engine.physics_ticks_per_second = previous_rate
	_check(at_30.distance_to(at_60) < 0.3 and at_60.distance_to(at_120) < 0.3, "Following is consistent at 30/60/120 physics ticks")
	await _test_obstacle_route()
	actor = _manager.get_actor()
	player = current_scene.get_node("Player")
	var before := actor.global_position
	root.get_node("SettingsMenu").open_menu()
	Input.action_press("move_right")
	await _ticks(10)
	Input.action_release("move_right")
	_check(actor.global_position.is_equal_approx(before), "Pause freezes companion")
	root.get_node("SettingsMenu").close_menu()

	# An actual overlap at the exit and the body-entered handler both ignore it.
	actor.set_physics_process(false)
	actor.global_position = Vector3(-0.8, 0.03, -5)
	current_scene.get_node("ToForestPath").call("_on_body_entered", actor)
	await _ticks(30)
	_check(current_scene.scene_file_path == "res://forest_clearing.tscn", "Companion never starts a scene transition")
	actor.set_physics_process(true)
	await _test_visual_animations()
	print("Companion: %s checks, %s failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _follow_at_rate(rate: int) -> Vector3:
	Engine.physics_ticks_per_second = rate
	await _ticks(5)
	var actor := _manager.get_actor()
	var player := current_scene.get_node("Player") as CharacterBody3D
	player.position = Vector3(-4, 0.95, 2.4)
	actor.position = Vector3(-4, 0.03, 3.8)
	actor.configure(_manager.active_monster, player)
	Input.action_press("move_right")
	await _ticks(rate)
	Input.action_release("move_right")
	await _ticks(rate * 3)
	_check(actor.position.x > -3, "Companion moves at physics rate %s" % rate)
	_check(actor.velocity.length() < 0.1, "Companion settles at physics rate %s" % rate)
	return actor.position


func _test_obstacle_route() -> void:
	var actor := _manager.get_actor()
	var player := current_scene.get_node("Player") as CharacterBody3D
	player.position = Vector3(0, 0.95, 2.4)
	actor.position = Vector3(-0.6, 0.03, 3.5)
	actor.velocity = Vector3.ZERO
	actor.configure(_manager.active_monster, player)
	# South -> east -> north -> west: route around the clearing's solid test block.
	for leg in [["move_right", 85], ["move_forward", 75], ["move_left", 60]]:
		Input.action_press(leg[0])
		await _ticks(leg[1])
		Input.action_release(leg[0])
	await _ticks(180)
	_check(actor.position.z < -1.2, "Breadcrumb route gets around rock instead of chasing through it")
	_check(actor.position.distance_to(Vector3(player.position.x, actor.position.y, player.position.z)) < 2.0, "Companion catches up after cornering")
	_check(actor.is_on_floor() and absf(actor.position.x) < 7.7 and absf(actor.position.z) < 5.7, "Companion remains on walkable area")
	_check(actor.velocity.length() < 0.1, "Stops after obstacle route")


func _test_visual_animations() -> void:
	var registry := MonsterRegistry.new()
	var definition := registry.get_monster(&"drako").duplicate() as MonsterDefinition
	var model := Node3D.new()
	var animator := AnimationPlayer.new()
	model.add_child(animator)
	animator.owner = model
	var library := AnimationLibrary.new()
	for clip in [&"rest", &"stride"]:
		var animation := Animation.new()
		animation.length = 1.0
		animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(clip, animation)
	animator.add_animation_library(&"", library)
	var packed := PackedScene.new()
	packed.pack(model)
	model.free()
	definition.visual_scene = packed
	definition.idle_animation = &"rest"
	definition.walk_animation = &"stride"
	var visual := MonsterVisual.new()
	root.add_child(visual)
	_check(visual.set_definition(definition), "Visual supports independent animation model")
	var player := visual.model.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	_check(player.current_animation == "rest", "Idle maps to species-specific clip")
	visual.set_walking(true)
	_check(player.current_animation == "stride", "Walk maps to species-specific clip")
	visual.set_walking(false)
	_check(player.current_animation == "rest", "Walk returns to idle")
	definition.walk_animation = &"missing"
	visual.set_walking(true)
	_check(player.current_animation == "rest", "Missing walk falls back to idle")
	definition.idle_animation = &"missing"
	visual.set_walking(false)
	_check(not player.is_playing(), "Missing clips stop safely")
	visual.free()


func _walk_to(action: String, destination: String) -> bool:
	Input.action_press(action)
	for frame in 180:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path == destination:
			Input.action_release(action)
			await _ticks(60)
			return true
	Input.action_release(action)
	return false

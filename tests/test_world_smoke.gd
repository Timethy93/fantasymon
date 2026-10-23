extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)


func _run() -> void:
	_check(change_scene_to_file("res://forest_clearing.tscn") == OK, "Load clearing")
	await scene_changed
	for frame in 10:
		await physics_frame
	var player := current_scene.get_node("Player") as CharacterBody3D
	_check(player.is_on_floor(), "Player stands on floor")
	_check(current_scene.get_node("Camera3D").fov == 34.0, "Fixed camera preserved")
	var start := player.position
	Input.action_press("move_right")
	for frame in 10:
		await physics_frame
	Input.action_release("move_right")
	_check(player.position.x > start.x, "Existing player movement works")
	var menu := root.get_node("SettingsMenu")
	menu.open_menu()
	_check(paused, "Settings pauses world")
	var paused_position := player.position
	Input.action_press("move_forward")
	for frame in 5:
		await physics_frame
	Input.action_release("move_forward")
	_check(player.position.is_equal_approx(paused_position), "Paused player does not move")
	root.get_node("SceneManager").travel_to("res://forest_path.tscn", &"FromForestClearing")
	_check(current_scene.scene_file_path == "res://forest_clearing.tscn", "Paused transition rejected")
	menu.close_menu()
	player.position = Vector3(0, 0.95, 0)
	_check(await _walk_to("move_forward", "res://forest_path.tscn"), "Walk A to B through Area3D")
	if current_scene.scene_file_path == "res://forest_path.tscn":
		player = current_scene.get_node("Player")
		_check(player.position.distance_to(Vector3(0.5, 0.901, 3.4)) < 0.2, "B entry point correct")
		_check(await _walk_to("move_backward", "res://forest_clearing.tscn"), "Walk B to A through Area3D")
	if current_scene.scene_file_path == "res://forest_clearing.tscn":
		player = current_scene.get_node("Player")
		_check(player.position.distance_to(Vector3(-0.8, 0.901, -3.4)) < 0.2, "A entry point correct")
	print("World smoke: %s failures" % _failures)
	quit(0 if _failures == 0 else 1)


func _walk_to(action: String, destination: String) -> bool:
	Input.action_press(action)
	for frame in 180:
		await physics_frame
		if current_scene != null and current_scene.scene_file_path == destination:
			Input.action_release(action)
			for settle in 30:
				await physics_frame
			return true
	Input.action_release(action)
	return false

extends SceneTree

var _checks := 0
var _failures := 0
var _actor: CompanionFollower
var _player: CharacterBody3D
var _metrics: Array[Dictionary] = []


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


func _reset(player_position: Vector3, actor_position: Vector3) -> void:
	for action in ["move_right", "move_left", "move_forward", "move_backward"]:
		Input.action_release(action)
	_player.position = player_position
	_actor.position = actor_position
	_actor.configure(_actor.monster, _player)
	await _ticks(5)


func _run() -> void:
	change_scene_to_file("res://forest_clearing.tscn")
	await scene_changed
	await _ticks(30)
	_actor = root.get_node("CompanionManager").get_actor()
	_player = current_scene.get_node("Player")
	var old_rate := Engine.physics_ticks_per_second
	var endpoints: Array[Vector3] = []
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		await _ticks(5)
		var metrics := {"rate": rate}
		await _ramp_and_brake(rate, metrics)
		endpoints.append(await _straight_start_stop(rate, metrics))
		await _curves(rate, metrics)
		await _obstacle(rate, metrics)
		_metrics.append(metrics)
	Engine.physics_ticks_per_second = old_rate
	_check(endpoints[0].distance_to(endpoints[1]) < 0.25 and endpoints[1].distance_to(endpoints[2]) < 0.25, "Comparable endpoints across all physics rates")
	print("MOTION_METRICS " + JSON.stringify(_metrics))
	print("Companion motion: %s checks, %s failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _ramp_and_brake(rate: int, metrics: Dictionary) -> void:
	await _reset(Vector3(0, 0.95, 2.4), Vector3(-5, 0.03, 2.4))
	_actor.position = Vector3(-5, 0.03, 2.4)
	_actor.configure(_actor.monster, _player)
	var quarter_speed := 0.0
	var half_speed := 0.0
	var maximum_speed := 0.0
	var maximum_step := 0.0
	var previous_velocity := Vector2.ZERO
	var previous_x := _actor.position.x
	var reverse_travel := 0.0
	var overshoot := 0.0
	for frame in rate * 4:
		await physics_frame
		var motion := Vector2(_actor.velocity.x, _actor.velocity.z)
		maximum_speed = maxf(maximum_speed, motion.length())
		maximum_step = maxf(maximum_step, motion.distance_to(previous_velocity))
		previous_velocity = motion
		reverse_travel += maxf(0.0, previous_x - _actor.position.x)
		previous_x = _actor.position.x
		overshoot = maxf(overshoot, _actor.position.x + _actor.follow_distance)
		if quarter_speed == 0.0 and _actor._trail_clock >= 0.25:
			quarter_speed = motion.length()
		if half_speed == 0.0 and _actor._trail_clock >= 0.5:
			half_speed = motion.length()
	_check(quarter_speed > 1.5 and quarter_speed < 3.0, "Gentle quarter-second ramp at %s Hz" % rate)
	_check(half_speed > 4.0 and half_speed < 5.2, "Normal speed after about half a second at %s Hz" % rate)
	_check(maximum_speed > _actor.movement_speed + 0.2 and maximum_speed <= _actor.catch_up_speed + 0.01, "Bounded catch-up speed at %s Hz" % rate)
	_check(maximum_step <= maxf(_actor.acceleration, _actor.deceleration) / rate + 0.01, "Acceleration and braking limits at %s Hz" % rate)
	_check(overshoot < 0.03 and reverse_travel < 0.01, "No endpoint overshoot or corrective wobble at %s Hz" % rate)
	_check(_actor.velocity.length() < 0.05, "Ramp test reaches quiet rest at %s Hz" % rate)
	metrics["quarter_second_speed"] = quarter_speed
	metrics["half_second_speed"] = half_speed
	metrics["peak_catch_up_speed"] = maximum_speed
	metrics["endpoint_overshoot"] = overshoot


func _straight_start_stop(rate: int, metrics: Dictionary) -> Vector3:
	await _reset(Vector3(-4, 0.95, 2.4), Vector3(-4, 0.03, 3.8))
	var previous := _actor.position
	var response := -1.0
	var backward_travel := 0.0
	Input.action_press("move_right")
	for frame in roundi(rate * 1.25):
		await physics_frame
		if frame == rate - 1:
			Input.action_release("move_right")
		if response < 0 and _actor.position.x > -3.99:
			response = float(frame + 1) / rate
		backward_travel += maxf(0, previous.x - _actor.position.x)
		previous = _actor.position
	Input.action_release("move_right")
	await _ticks(rate)
	var resting_position := _actor.position
	var max_rest_drift := 0.0
	for frame in rate:
		await physics_frame
		max_rest_drift = maxf(max_rest_drift, _actor.position.distance_to(resting_position))
	_check(response >= _actor.follow_delay - 0.1 and response <= _actor.follow_delay + 0.2, "Delayed sideways start at %s Hz" % rate)
	_check(backward_travel < 0.02, "No reversals while tracking a straight line at %s Hz" % rate)
	_check(max_rest_drift < 0.015 and _actor.velocity.length() < 0.05, "No rest jitter at %s Hz" % rate)
	metrics["response_seconds"] = response
	metrics["wrong_way_distance"] = backward_travel
	metrics["rest_drift"] = max_rest_drift
	return _actor.position


func _curves(rate: int, metrics: Dictionary) -> void:
	await _reset(Vector3(-5, 0.95, 2.4), Vector3(-5, 0.03, 3.8))
	var travelled := 0.0
	var previous := _actor.position
	# Continuous left-side loop, clear of the test rock and both exits.
	for leg in [["move_right", 0.9], ["move_forward", 0.5], ["move_left", 0.9], ["move_backward", 0.5]]:
		Input.action_press(leg[0])
		for frame in roundi(rate * leg[1]):
			await physics_frame
			travelled += _actor.position.distance_to(previous)
			previous = _actor.position
		Input.action_release(leg[0])
	await _ticks(rate * 2)
	_check(_actor._waypoints.size() <= 1, "Free sight discards obsolete loop at %s Hz" % rate)
	_check(_actor.position.distance_to(Vector3(_player.position.x, _actor.position.y, _player.position.z)) < 1.8, "Catches up through clear curves at %s Hz" % rate)
	_check(_actor.velocity.length() < 0.05, "Settles after curve at %s Hz" % rate)
	_check(travelled < 13.0, "Does not retrace entire historical loop at %s Hz" % rate)
	metrics["curve_distance"] = travelled


func _obstacle(rate: int, metrics: Dictionary) -> void:
	await _reset(Vector3(0, 0.95, 2.4), Vector3(-0.6, 0.03, 3.5))
	var crossed_rock := false
	var stalled_frames := 0
	var current_stall := 0
	for leg in [["move_right", 1.4], ["move_forward", 1.25], ["move_left", 1.0]]:
		Input.action_press(leg[0])
		for frame in roundi(rate * leg[1]):
			await physics_frame
			crossed_rock = crossed_rock or (absf(_actor.position.x - 3) < 1.2 and absf(_actor.position.z) < 0.9)
			var gap := Vector2(_actor.position.x - _player.position.x, _actor.position.z - _player.position.z).length()
			if gap > 2.0 and _actor.get_real_velocity().length() < 0.05:
				current_stall += 1
				stalled_frames = maxi(stalled_frames, current_stall)
			else:
				current_stall = 0
		Input.action_release(leg[0])
	var settle_time := -1.0
	for frame in rate * 3:
		await physics_frame
		var gap := Vector2(_actor.position.x - _player.position.x, _actor.position.z - _player.position.z).length()
		if settle_time < 0 and gap < 1.8 and _actor.velocity.length() < 0.1:
			settle_time = float(frame + 1) / rate
	_check(not crossed_rock and _actor.is_on_floor(), "Capsule shortcuts respect obstacle at %s Hz" % rate)
	_check(_actor.position.z < -1.2, "Gets behind obstacle at %s Hz" % rate)
	_check(settle_time >= 0 and settle_time <= 1.2, "No long waypoint detour at %s Hz" % rate)
	_check(float(stalled_frames) / rate < 0.3, "No prolonged obstacle stall at %s Hz" % rate)
	metrics["obstacle_settle_seconds"] = settle_time
	metrics["longest_stall_seconds"] = float(stalled_frames) / rate

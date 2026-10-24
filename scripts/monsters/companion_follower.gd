class_name CompanionFollower
extends CharacterBody3D

@export_range(0.0, 3.0, 0.05) var follow_delay: float = 1.0
@export_range(0.8, 3.0, 0.1) var follow_distance: float = 1.5
@export_range(0.0, 1.0, 0.01) var restart_margin: float = 0.08
@export_range(0.1, 10.0, 0.1) var movement_speed: float = 4.5
@export_range(1.0, 50.0, 0.5) var acceleration: float = 9.0
@export_range(1.0, 50.0, 0.5) var deceleration: float = 14.0
@export_range(0.1, 10.0, 0.1) var catch_up_speed: float = 6.0
@export_range(0.1, 5.0, 0.1) var catch_up_distance: float = 1.0
@export_range(1.0, 10.0, 0.5) var arrival_response: float = 4.0

const SAMPLE_SPACING := 0.18
const WAYPOINT_RADIUS := 0.2
const MAX_WAYPOINTS := 512
const MAX_SHORTCUT_CHECKS := 16
const REST_TOLERANCE := 0.03

var monster: MonsterInstance
var target: CharacterBody3D
var _waypoints: Array[Vector3] = []
var _last_sample: Vector3
var _following := false
var _trail_clock: float = 0.0
var _history: Array[Dictionary] = []
var _travel_query := PhysicsShapeQueryParameters3D.new()

@onready var visual: MonsterVisual = $Visual
@onready var _collider: CollisionShape3D = $CollisionShape3D


func configure(data: MonsterInstance, player: CharacterBody3D) -> void:
	monster = data
	target = player
	_following = false
	velocity = Vector3.ZERO
	_last_sample = player.global_position
	_waypoints.assign([_last_sample])
	_trail_clock = 0.0
	# Known entry position is immediately usable; no spawn/transition countdown.
	_history.assign([
		{"time": -maxf(follow_delay, 0.001), "position": _last_sample},
		{"time": 0.0, "position": _last_sample}
	])


func _ready() -> void:
	if monster == null or target == null or not visual.set_definition(monster.definition):
		push_error("Companion needs valid monster data, a player and a Node3D visual.")
		set_physics_process(false)
		return
	_travel_query.shape = _collider.shape
	_travel_query.collision_mask = collision_mask
	_travel_query.margin = 0.02
	_travel_query.exclude = [get_rid(), target.get_rid()]


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if get_node("/root/SceneManager").transition_in_progress:
		velocity = Vector3.ZERO
		visual.set_walking(false)
		return

	var sample := _delayed_sample(delta)
	var goal: Vector3 = sample.position
	var delayed_motion: Vector3 = sample.velocity
	if _horizontal(goal - _last_sample).length() >= SAMPLE_SPACING and _waypoints.size() < MAX_WAYPOINTS:
		_last_sample = goal
		_waypoints.append(goal)
	while not _waypoints.is_empty() and _horizontal(_waypoints[0] - global_position).length() <= WAYPOINT_RADIUS:
		_waypoints.pop_front()

	var offset := _horizontal(goal - global_position)
	var distance := offset.length()
	# Extra speed corrects lag behind the mature route, never the intended delay.
	var speed_limit := _speed_limit(distance)
	# Temporal spacing while walking; blend to personal space as the delayed
	# route reaches the player's current position after a stop. Never steer
	# toward the live position or use its live direction as feed-forward.
	var stop_radius := maxf(0.0, follow_distance - _horizontal(target.global_position - goal).length())
	var track_motion := delayed_motion.length() > 0.1 and distance > stop_radius + 0.001
	if track_motion or distance > stop_radius + restart_margin:
		_following = true
	elif distance <= stop_radius + REST_TOLERANCE:
		_following = false

	var desired := Vector3.ZERO
	if _can_travel_to(goal):
		# Only mature points may be skipped. Current/future player samples remain
		# in the timestamp buffer even when the live player is directly visible.
		_waypoints.assign([goal])
		_last_sample = goal
		if _following:
			if track_motion:
				desired = delayed_motion + offset.normalized() * (distance - stop_radius) * arrival_response
				desired = desired.limit_length(speed_limit)
				desired = desired.limit_length(maxf(0.0, distance - stop_radius) / delta)
				if not _can_travel_to(global_position + desired * 0.2):
					desired = _arrival_velocity(offset, stop_radius, delta, speed_limit)
			else:
				desired = _arrival_velocity(offset, stop_radius, delta, speed_limit)
	elif _following:
		var destination := _visible_waypoint()
		desired = _arrival_velocity(_horizontal(destination - global_position), WAYPOINT_RADIUS * 0.5, delta, speed_limit)

	var current := _horizontal(velocity)
	var slowing := desired.length_squared() < current.length_squared() or desired.dot(current) < 0.0
	var response := deceleration if slowing else acceleration
	var horizontal_velocity := current.move_toward(desired, response * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	var motion := _horizontal(get_real_velocity())
	if motion.length() > 0.15:
		visual.set_walking(true)
		var facing := atan2(-motion.x, -motion.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, facing, 1.0 - exp(-12.0 * delta))
	elif motion.length() < 0.05:
		visual.set_walking(false)


func _delayed_sample(delta: float) -> Dictionary:
	# Physics delta excludes menu pauses and the transition branch above.
	_trail_clock += delta
	_history.append({"time": _trail_clock, "position": target.global_position})
	var cutoff := _trail_clock - maxf(0.0, follow_delay)
	while _history.size() > 2 and float(_history[1].time) <= cutoff:
		_history.pop_front()
	var before := _history[0]
	var after := _history[1]
	var span := maxf(0.000001, float(after.time) - float(before.time))
	var fraction := clampf((cutoff - float(before.time)) / span, 0.0, 1.0)
	var start: Vector3 = before.position
	var finish: Vector3 = after.position
	return {
		"position": start.lerp(finish, fraction),
		"velocity": _horizontal(finish - start) / span
	}


func _speed_limit(route_lag: float) -> float:
	var amount := clampf((route_lag - catch_up_distance) / catch_up_distance, 0.0, 1.0)
	return lerpf(movement_speed, maxf(movement_speed, catch_up_speed), amount)


func _arrival_velocity(offset: Vector3, stop_radius: float, delta: float, speed_limit: float) -> Vector3:
	var remaining := maxf(0.0, offset.length() - stop_radius)
	if remaining <= REST_TOLERANCE:
		return Vector3.ZERO
	# Proportional slowdown plus a physical braking-distance and step-size cap.
	var speed := minf(speed_limit, remaining * arrival_response)
	# Conservative discrete braking envelope uses the same deceleration as the
	# single velocity integrator, including one physics step of braking margin.
	var braking_step := deceleration * delta
	speed = minf(speed, sqrt(braking_step * braking_step + 2.0 * deceleration * remaining) - braking_step)
	speed = minf(speed, remaining / delta)
	return offset.normalized() * speed


func _visible_waypoint() -> Vector3:
	# Check farthest points first, with a bounded physics-query budget.
	var stride := maxi(1, ceili(float(_waypoints.size()) / MAX_SHORTCUT_CHECKS))
	for index in range(_waypoints.size() - 1, -1, -stride):
		if _can_travel_to(_waypoints[index]):
			var destination := _waypoints[index]
			_waypoints = _waypoints.slice(index)
			return destination
	if not _waypoints.is_empty() and _can_travel_to(_waypoints[0]):
		return _waypoints[0]
	return global_position


func _can_travel_to(destination: Vector3) -> bool:
	var transform := _collider.global_transform
	# Ignore floor contact on the existing flat segments, but retain full body
	# width for rock edges and walls. A thin ray would cut obstructed corners.
	transform.origin.y += 0.05
	_travel_query.transform = transform
	_travel_query.motion = _horizontal(destination - global_position)
	if _travel_query.motion.length_squared() < 0.000001:
		return true
	var fractions := get_world_3d().direct_space_state.cast_motion(_travel_query)
	return fractions[0] >= 0.999


func _horizontal(value: Vector3) -> Vector3:
	value.y = 0.0
	return value

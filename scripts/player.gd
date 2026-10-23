class_name FantasyMonPlayer
extends CharacterBody3D

@export var movement_speed: float = 4.0

@onready var camera: Camera3D = %Camera3D


func _physics_process(delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	# Project the camera axes onto the ground so movement follows the screen.
	var camera_right := camera.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var camera_back := camera.global_basis.z
	camera_back.y = 0.0
	camera_back = camera_back.normalized()
	var direction := camera_right * input_direction.x + camera_back * input_direction.y

	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0
	move_and_slide()

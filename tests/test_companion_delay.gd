extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame

func run() -> void:
	change_scene_to_file("res://forest_clearing.tscn")
	await scene_changed
	await ticks(45)
	var actor: CompanionFollower = root.get_node("CompanionManager").get_actor()
	var player: CharacterBody3D = current_scene.get_node("Player")
	var original_rate := Engine.physics_ticks_per_second
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		for delay in [0.5, 1.0, 1.5]:
			player.position = Vector3(-6, 0.95, 2.4)
			actor.position = Vector3(-6, 0.03, 2.4)
			actor.follow_delay = delay
			actor.configure(actor.monster, player)
			await ticks(5)
			Input.action_press("move_right")
			var player_cross := -1.0
			var actor_cross := -1.0
			for frame in roundi(rate * 3.0):
				await physics_frame
				var time: float = float(frame + 1) / rate
				if player_cross < 0 and player.position.x >= -1:
					player_cross = time
				if actor_cross < 0 and actor.position.x >= -1:
					actor_cross = time
			Input.action_release("move_right")
			var measured := actor_cross - player_cross
			print("DELAY %sHz requested=%s measured=%s" % [rate, delay, measured])
			check(actor_cross > 0 and absf(measured - delay) < 0.2, "Temporal route alignment %sHz / %ss" % [rate, delay])
			await ticks(roundi(rate * (delay + 2)))
			var rest := actor.position
			await ticks(rate)
			check(actor.position.distance_to(rest) < 0.015 and actor.velocity.length() < 0.05, "Stable long stop %sHz / %ss" % [rate, delay])
		# Warm straight route then turn north in a clear corridor beside the rock.
		actor.follow_delay = 1.0
		player.position = Vector3(-6, 0.95, 2.4)
		actor.position = Vector3(-6, 0.03, 2.4)
		actor.configure(actor.monster, player)
		Input.action_press("move_right")
		await ticks(roundi(rate * 1.7))
		Input.action_release("move_right")
		Input.action_press("move_forward")
		var turn_time := -1.0
		for frame in roundi(rate * 1.7):
			await physics_frame
			if turn_time < 0 and actor.position.z < 2.25:
				turn_time = float(frame + 1) / rate
			if frame == roundi(rate * 0.8):
				Input.action_release("move_forward")
		print("TURN %sHz measured=%s" % [rate, turn_time])
		check(turn_time >= 0.9 and turn_time <= 1.25, "Turn follows old route before new direction %sHz" % rate)
		await ticks(rate * 3)
		# An already distant spawn approaches its known entry anchor immediately.
		player.position = Vector3(-4, 0.95, 2)
		actor.position = Vector3(-4, 0.03, 4.5)
		actor.configure(actor.monster, player)
		await ticks(roundi(rate * 0.2))
		check(actor.position.z < 4.4, "No artificial spawn countdown %sHz" % rate)
	Engine.physics_ticks_per_second = original_rate
	print("Companion delay: %s checks, %s failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

class_name FantasyMonSceneManager
extends Node

signal transition_finished(scene_path: String, entry_name: StringName)
signal travel_failed(message_key: String)

const FADE_SECONDS := 0.18

var transition_in_progress: bool = false
var _fade: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func travel_to(scene_path: String, entry_name: StringName) -> void:
	if get_tree().paused or transition_in_progress:
		return
	# Validate the destination before touching the running segment.
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		_report_error("SEGMENT_LOAD_FAILED", scene_path)
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_report_error("SEGMENT_LOAD_FAILED", scene_path)
		return
	var preview := packed.instantiate()
	var entry_path := NodePath("EntryPoints/" + String(entry_name))
	var valid := (
		preview.get_node_or_null(entry_path) is Marker3D
		and preview.get_node_or_null("Player") is CharacterBody3D
	)
	preview.free()
	if not valid:
		_report_error("SEGMENT_ENTRY_INVALID", "%s: %s" % [scene_path, entry_name])
		return

	transition_in_progress = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var old_player := get_tree().current_scene.get_node("Player") as CharacterBody3D
	var was_processing := old_player.is_physics_processing()
	old_player.set_physics_process(false)
	old_player.velocity = Vector3.ZERO
	await _fade_to(1.0)

	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		_report_error("SEGMENT_LOAD_FAILED", "%s (%s)" % [scene_path, error])
		old_player.set_physics_process(was_processing)
		await _fade_to(0.0)
		_finish_transition()
		return
	await get_tree().scene_changed

	var segment := get_tree().current_scene
	var player := segment.get_node("Player") as CharacterBody3D
	var entry := segment.get_node(entry_path) as Marker3D
	player.set_physics_process(false)
	player.global_transform = entry.global_transform
	player.velocity = Vector3.ZERO
	# Let Area3D overlaps settle while transitions and movement are blocked.
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _fade_to(0.0)
	player.set_physics_process(true)
	_finish_transition()
	transition_finished.emit(scene_path, entry_name)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished


func _report_error(message_key: String, detail: String) -> void:
	push_error("%s (%s)" % [tr(message_key), detail])
	travel_failed.emit(message_key)


func _finish_transition() -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_in_progress = false

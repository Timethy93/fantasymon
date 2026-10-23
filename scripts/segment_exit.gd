class_name SegmentExit
extends Area3D

@export_file("*.tscn") var target_scene: String
@export var target_entry: StringName


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	# Defer scene changes out of the physics signal callback.
	get_node("/root/SceneManager").call_deferred(
		"travel_to", target_scene, target_entry
	)

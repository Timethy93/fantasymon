@tool
class_name PrerenderedBackdrop
extends Node3D

@export var background_texture: Texture2D
@export var baked_camera_transform: Transform3D = Transform3D(
	Basis.from_euler(Vector3(-PI / 3.0, 0, 0)), Vector3(0, 18, 10.4)
)
@export var baked_fov: float = 34.0
@export var baked_offsets: Vector2 = Vector2.ZERO
@export_tool_button("Bake background.png") var bake_button: Callable = bake_background

var _baking: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var segment := get_parent()
	var camera := segment.get_node("Camera3D") as Camera3D
	var calibration_valid := (
		background_texture != null
		and camera.transform.is_equal_approx(baked_camera_transform)
		and is_equal_approx(camera.fov, baked_fov)
		and camera.projection == Camera3D.PROJECTION_PERSPECTIVE
		and camera.keep_aspect == Camera3D.KEEP_HEIGHT
		and Vector2(camera.h_offset, camera.v_offset).is_equal_approx(baked_offsets)
		and background_texture.get_width() * 9 == background_texture.get_height() * 16
	)
	if not calibration_valid:
		push_error(tr("BACKGROUND_CALIBRATION_INVALID"))
		get_node("/root/SceneManager").travel_failed.emit("BACKGROUND_CALIBRATION_INVALID")
		return

	var screen := MeshInstance3D.new()
	screen.name = "BackgroundImage"
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	screen.mesh = quad
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var background_material := ShaderMaterial.new()
	background_material.shader = load("res://shaders/prerendered_background.gdshader")
	background_material.set_shader_parameter("background_image", background_texture)
	screen.material_override = background_material
	camera.add_child(screen)
	screen.position = Vector3(0, 0, -100)
	screen.extra_cull_margin = 1000.0

	var source := segment.get_node("ForestBackdrop/TestRock") as MeshInstance3D
	var proxy := MeshInstance3D.new()
	proxy.name = "TestRockOcclusion"
	proxy.mesh = source.mesh
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var occlusion_material := ShaderMaterial.new()
	occlusion_material.shader = load("res://shaders/prerendered_occluder.gdshader")
	occlusion_material.set_shader_parameter("background_image", background_texture)
	proxy.material_override = occlusion_material
	add_child(proxy)
	proxy.global_transform = source.global_transform
	segment.get_node("ForestBackdrop").hide()
	segment.get_node("WorldGeometry/Ground/Visual").hide()


func bake_background() -> void:
	if not Engine.is_editor_hint() or _baking:
		return
	_baking = true
	var baker: RefCounted = load("res://tools/bake_forest_background.gd").new()
	var result: Error = await baker.call("bake", get_tree(), get_parent())
	if result == OK:
		var camera := get_parent().get_node("Camera3D") as Camera3D
		baked_camera_transform = camera.transform
		baked_fov = camera.fov
		baked_offsets = Vector2(camera.h_offset, camera.v_offset)
		EditorInterface.get_resource_filesystem().scan()
		EditorInterface.mark_scene_as_unsaved()
	_baking = false

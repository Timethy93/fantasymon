@tool
extends RefCounted

const OUTPUT := "res://assets/backgrounds/forest/forest_clearing/background.png"
const IMAGE_SIZE := Vector2i(1920, 1080)


func bake(tree: SceneTree, segment: Node3D) -> Error:
	# Isolated world: no Player, exit labels, menus, transition overlay or gameplay.
	var viewport := SubViewport.new()
	viewport.name = "FantasyMonBackgroundBake"
	viewport.size = IMAGE_SIZE
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var stage := Node3D.new()
	viewport.add_child(stage)
	for path in ["ForestBackdrop", "WorldGeometry/Ground", "DirectionalLight3D", "WorldEnvironment", "Camera3D"]:
		var original := segment.get_node(path)
		var copy := original.duplicate()
		stage.add_child(copy)
		if copy is Node3D:
			copy.transform = original.transform
		if copy is VisualInstance3D:
			copy.visible = true
		if path == "ForestBackdrop":
			copy.visible = true
	tree.root.add_child(viewport)
	for frame in 3:
		await tree.process_frame
		RenderingServer.force_draw(false)
	var image := viewport.get_texture().get_image()
	var error := image.save_png(OUTPUT)
	viewport.queue_free()
	if error != OK:
		push_error("Background bake failed: %s (%s)" % [OUTPUT, error])
		return error
	print("Background baked: %s (%sx%s); camera: %s" % [
		OUTPUT, IMAGE_SIZE.x, IMAGE_SIZE.y, segment.get_node("Camera3D").transform
	])
	return OK

extends "res://ui/game/menu_panel.gd"

const ICONS := {
	&"hp": preload("res://assets/ui/icons/stats/hp.png"),
	&"mp": preload("res://assets/ui/icons/stats/mp.png"),
	&"atk": preload("res://assets/ui/icons/stats/atk.png"),
	&"defense": preload("res://assets/ui/icons/stats/defense.png"),
	&"speed": preload("res://assets/ui/icons/stats/speed.png"),
	&"brain": preload("res://assets/ui/icons/stats/brain.png"),
	&"satiety": preload("res://assets/ui/icons/stats/satiety.png"),
}
var monster_name: Label
var fields: Dictionary = {}
var refusal: Label
var preview: SubViewport
var preview_container: SubViewportContainer
var preview_model: Node3D
var preview_camera: Camera3D
var _preview_source: PackedScene
var _preview_bounds := AABB()
var _has_preview_bounds := false

func build_content() -> void:
	# Compact only this menu's chrome to leave room for seven larger stat rows.
	var content := panel.get_child(0) as VBoxContainer
	content.add_theme_constant_override("separation", 4)
	content.get_child(0).add_theme_font_size_override("font_size", 22)
	body.add_theme_constant_override("separation", 2)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	body.add_child(header)
	monster_name = Label.new()
	monster_name.add_theme_font_size_override("font_size", 18)
	monster_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(monster_name)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	body.add_child(columns)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 0)
	columns.add_child(stats)
	for field in ICONS:
		_add_field(stats, field)
	preview_container = SubViewportContainer.new()
	preview_container.custom_minimum_size = Vector2(180, 210)
	preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_container.stretch = true
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(preview_container)
	preview = SubViewport.new()
	preview.own_world_3d = true
	preview.transparent_bg = true
	preview.handle_input_locally = false
	preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
	preview_container.add_child(preview)
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(2.5, 1.6, 3.5)
	preview_camera.current = true
	preview_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	preview.add_child(preview_camera)
	preview_camera.look_at(Vector3(0, 0.7, 0))
	preview.size_changed.connect(_fit_preview_camera)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	preview.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.5
	preview.add_child(environment)
	visibility_changed.connect(func():
		preview.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if visible else SubViewport.UPDATE_DISABLED)
	refusal = Label.new()
	refusal.add_theme_font_size_override("font_size", 16)
	refusal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refusal.text = "FEED_REFUSED"
	header.add_child(refusal)

func _add_field(parent: Container, field: StringName) -> void:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#142338")
	background.content_margin_left = 4
	background.content_margin_right = 4
	background.content_margin_top = 1
	background.content_margin_bottom = 1
	box.add_theme_stylebox_override("panel", background)
	parent.add_child(box)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var icon := TextureRect.new()
	icon.texture = ICONS[field]
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 18)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	fields[field] = {"box": box, "row": row, "icon": icon, "label": label, "value": value}

func refresh() -> void:
	if monster_name == null or not visible:
		return
	var monster: MonsterInstance = get_node("/root/CompanionManager").active_monster
	monster_name.text = tr(monster.definition.display_name_key) if monster != null else tr("FEED_NO_MONSTER")
	for field in fields:
		var entry: Dictionary = fields[field]
		entry.box.visible = monster != null
		var key := "SATIETY" if field == &"satiety" else "STAT_" + String(field).to_upper()
		entry.icon.tooltip_text = tr(key)
		entry.label.text = tr(key)
		if monster == null:
			continue
		if field in [&"hp", &"mp", &"satiety"]:
			var maximum: float = 100.0 if field == &"satiety" else float(monster.stats.get(field))
			var current: float = monster.satiety if field == &"satiety" else float(monster.get("current_" + String(field)))
			entry.value.text = "%.1f / 100" % current if field == &"satiety" else "%d / %d" % [int(current), int(maximum)]
		else:
			entry.value.text = str(monster.stats.get(field))
	refusal.visible = monster != null and monster.refusing_food
	_update_preview(monster.definition.visual_scene if monster != null else null)

func _update_preview(source: PackedScene) -> void:
	if source == _preview_source:
		return
	_preview_source = source
	if is_instance_valid(preview_model):
		preview.remove_child(preview_model)
		preview_model.queue_free()
	preview_model = null
	_has_preview_bounds = false
	if source == null:
		return
	# Keep the entire model scene, including future AnimationPlayer/AnimationTree nodes.
	var model := source.instantiate()
	if not model is Node3D:
		model.free()
		return
	preview_model = model
	# Preview stays static for now; no animation playback or world-body simulation.
	preview_model.process_mode = Node.PROCESS_MODE_DISABLED
	preview.add_child(preview_model)
	_collect_preview_bounds(preview_model)
	_fit_preview_camera()

func _collect_preview_bounds(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
		# Include every mesh's full ancestor transform without changing model scale.
		var bounds: AABB = node.global_transform * node.get_aabb()
		_preview_bounds = _preview_bounds.merge(bounds) if _has_preview_bounds else bounds
		_has_preview_bounds = true
	for child in node.get_children():
		_collect_preview_bounds(child)

func _fit_preview_camera() -> void:
	if not _has_preview_bounds or preview.size.x <= 0 or preview.size.y <= 0:
		return
	var center := _preview_bounds.get_center()
	var direction := Vector3(2.5, 0.9, 3.5).normalized()
	var camera_basis := Basis.looking_at(-direction)
	var inverse_basis := camera_basis.inverse()
	var tan_vertical := tan(deg_to_rad(preview_camera.fov) * 0.5)
	var tan_horizontal := tan_vertical * float(preview.size.x) / float(preview.size.y)
	var distance := 0.001
	# Project all eight corners into camera axes, including depth. Add 10% room.
	for index in 8:
		var offset: Vector3 = inverse_basis * (_preview_bounds.get_endpoint(index) - center)
		distance = maxf(distance, offset.z + maxf(absf(offset.x) / tan_horizontal, absf(offset.y) / tan_vertical) * 1.1)
	preview_camera.transform = Transform3D(camera_basis, center + direction * distance)
	preview_camera.near = maxf(0.00001, distance * 0.001)
	preview_camera.far = maxf(preview_camera.near + 1, distance + _preview_bounds.size.length() * 2)

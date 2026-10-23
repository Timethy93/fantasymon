extends SceneTree

var _checks := 0
var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)


func _run() -> void:
	var registry := MonsterRegistry.new()
	_check(registry.validate_all().is_empty(), "All shipped definitions validate")
	var drako := registry.get_monster(&"drako")
	_check(drako != null, "Find Drako by stable ID")
	if drako == null:
		quit(1)
		return
	_check(registry.get_monster(&"drako") == drako, "Registry returns shared definition")
	_check(MonsterRegistry.new().get_monster(&"drako") == drako, "ResourceLoader shares definitions across registries")
	for id in [&"", &"../drako", &"Drako", &"not_registered"]:
		_check(registry.get_monster(id) == null, "Invalid/unknown ID returns null: %s" % id)
		_check(not registry.last_error.is_empty(), "Lookup failure has diagnostic")
	registry.get_monster(&"drako")
	_check(registry.last_error.is_empty(), "Successful lookup clears diagnostic")
	for id in [&"slimo", &"fenri"]:
		var definition := registry.get_monster(id)
		_check(definition != null and definition.monster_id == id, "Find other species: %s" % id)
		var visual := definition.visual_scene.instantiate()
		_check(visual is Node3D, "Visual is independent 3D scene")
		visual.free()
	_check(MonsterDefinition.EvolutionStage.size() == 7, "Seven evolution stages")

	var first := MonsterInstance.create(drako)
	var second := MonsterInstance.create(drako)
	_check(first != null and second != null, "Create concrete monsters")
	_check(first.instance_id != second.instance_id, "Unique instance IDs")
	_check(String(first.instance_id).length() == 32, "128-bit identity")
	_check(first.definition == drako and second.definition == drako, "Species is shared")
	_check(first.stats != drako.base_stats and first.stats != second.stats, "Stats resources are owned independently")
	for field in MonsterStats.FIELDS:
		_check(first.stats.get(field) == drako.base_stats.get(field), "Initialize base stat: %s" % field)
	first.stats.atk = 45
	_check(first.stats.atk == 45 and drako.base_stats.atk == 20 and second.stats.atk == 20, "Training-like data mutation isolates species and sibling")

	first.current_hp = 7
	first.current_mp = 3
	_check(first.stats.hp == 120 and first.stats.mp == 40, "Vitals do not modify maxima")
	_check(second.current_hp == 120 and second.current_mp == 40, "Sibling vitals are independent")
	first.stats.hp = 5
	first.stats.mp = 2
	_check(first.current_hp == 5 and first.current_mp == 2, "Reducing maxima clamps vitals")
	first.stats.hp = 200
	first.stats.mp = 100
	_check(first.current_hp == 5 and first.current_mp == 2, "Increasing maxima does not heal")
	first.current_hp = -999
	first.current_mp = -999
	_check(first.current_hp == 0 and first.current_mp == 0, "Vitals allow zero, never negative")
	first.current_hp = 0x7fffffffffffffff
	first.current_mp = 0x7fffffffffffffff
	_check(first.current_hp == 200 and first.current_mp == 100, "Vitals cannot exceed individual maxima")

	first.stats = drako.base_stats
	first.stats.atk = 50
	_check(drako.base_stats.atk == 20, "Reassigning species stats copies")
	second.stats = first.stats
	second.stats.atk = 60
	_check(first.stats.atk == 50 and second.stats.atk == 60, "Reassigning sibling stats copies")
	var bounded := MonsterStats.new()
	for field in MonsterStats.FIELDS:
		bounded.set(field, -999)
		_check(bounded.get(field) == (MonsterStats.HP_MIN if field == &"hp" else MonsterStats.TECHNICAL_MIN), "Lower bound: %s" % field)
		bounded.set(field, 0x7fffffffffffffff)
		_check(bounded.get(field) == MonsterStats.TECHNICAL_MAX, "Upper bound: %s" % field)
		bounded.adjust(field, 0x7fffffffffffffff)
		_check(bounded.get(field) == MonsterStats.TECHNICAL_MAX, "Extreme increment saturates without overflow: %s" % field)
		bounded.adjust(field, -0x7fffffffffffffff)
		_check(bounded.get(field) == (MonsterStats.HP_MIN if field == &"hp" else MonsterStats.TECHNICAL_MIN), "Extreme decrement: %s" % field)
	_check(not bounded.adjust(&"not_a_stat", 5), "Unknown stat rejected")
	_check(MonsterInstance.create(null) == null, "Null species rejected")
	var invalid := MonsterDefinition.new()
	_check(MonsterInstance.create(invalid) == null, "Incomplete species rejected")
	invalid.monster_id = &"invalid_stage"
	invalid.display_name_key = &"MONSTER_DRAKO_NAME"
	invalid.base_stats = bounded
	invalid.visual_scene = drako.visual_scene
	invalid.set("evolution_stage", 99)
	_check(not invalid.validation_errors().is_empty(), "Invalid evolution stage rejected")

	_test_new_species(drako)
	var previous_locale := TranslationServer.get_locale()
	for language in ["en", "de"]:
		TranslationServer.set_locale(language)
		_check(TranslationServer.translate(drako.display_name_key) == "Drako", "Translated species name: %s" % language)
	TranslationServer.set_locale(previous_locale)
	print("Monster foundation: %s checks, %s failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_new_species(template: MonsterDefinition) -> void:
	var directory := "res://.godot/monster_test_" + Crypto.new().generate_random_bytes(8).hex_encode()
	_check(DirAccess.make_dir_recursive_absolute(directory) == OK, "Create isolated test directory")
	var fresh := MonsterDefinition.new()
	fresh.monster_id = &"new_species"
	fresh.display_name_key = &"MONSTER_DRAKO_NAME"
	fresh.base_stats = template.base_stats.copy()
	fresh.base_stats.brain = 77
	fresh.visual_scene = template.visual_scene
	var path := directory.path_join("new_species.tres")
	_check(ResourceSaver.save(fresh, path) == OK, "Save new editor resource")
	var registry := MonsterRegistry.new(directory)
	var loaded := registry.get_monster(&"new_species")
	_check(loaded != null, "New species found with unchanged registry code")
	if loaded != null:
		var individual := MonsterInstance.create(loaded)
		_check(individual.stats.brain == 77, "Generic instance creation supports new species")
		_check(registry.validate_all().is_empty(), "New directory validates")
	_check(ResourceSaver.save(fresh, directory.path_join("alias.tres")) == OK, "Create mismatched/duplicate-ID fixture")
	_check(registry.get_monster(&"alias") == null, "Same species ID under different filename rejected")
	_check(not registry.validate_all().is_empty(), "Catalog validation catches duplicate/mismatched ID")
	var wrong_type := MonsterStats.new()
	_check(ResourceSaver.save(wrong_type, directory.path_join("wrong_type.tres")) == OK, "Create invalid resource fixture")
	_check(registry.get_monster(&"wrong_type") == null, "Wrong resource type rejected")
	for filename in ["new_species.tres", "alias.tres", "wrong_type.tres"]:
		DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)

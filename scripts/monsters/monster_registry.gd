class_name MonsterRegistry
extends RefCounted

const DEFINITIONS_DIRECTORY := "res://data/monsters/definitions"

var _directory: String
var _cache: Dictionary[StringName, MonsterDefinition] = {}
# Developer diagnostic, not a player-facing string.
var last_error: String = ""


func _init(directory: String = DEFINITIONS_DIRECTORY) -> void:
	_directory = directory


func get_monster(id: StringName) -> MonsterDefinition:
	last_error = ""
	if not MonsterDefinition.is_valid_id(id):
		last_error = "Invalid monster ID: %s" % id
		return null
	if _cache.has(id):
		return _cache[id]
	var path := _directory.path_join(String(id) + ".tres")
	if not ResourceLoader.exists(path):
		last_error = "Monster definition not found: %s" % id
		return null
	var definition := load(path) as MonsterDefinition
	if definition == null:
		last_error = "Not a MonsterDefinition: %s" % path
		return null
	var errors := definition.validation_errors()
	if definition.monster_id != id:
		errors.append("Resource ID must match its unique filename: %s" % path)
	if not errors.is_empty():
		last_error = "; ".join(errors)
		return null
	_cache[id] = definition
	return definition


# Explicit authoring/test validation, not required for lazy runtime lookup.
# ResourceLoader lists original names even in exported PCK files.
func validate_all() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	for filename in ResourceLoader.list_directory(_directory):
		if filename.ends_with(".tres"):
			var id := StringName(filename.get_basename())
			var definition := get_monster(id)
			if definition == null:
				errors.append(last_error)
			elif seen.has(definition.monster_id):
				errors.append("Duplicate monster ID: %s" % definition.monster_id)
			else:
				seen[definition.monster_id] = true
	return errors

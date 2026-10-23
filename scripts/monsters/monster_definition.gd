class_name MonsterDefinition
extends Resource

# Explicit stable values; do not reorder/renumber when extending save support.
enum EvolutionStage {
	BABY = 0,
	TRAINING = 1,
	KID = 2,
	TEEN = 3,
	ADULT = 4,
	ASCENDED = 5,
	MASTER = 6,
}

@export var monster_id: StringName
@export var display_name_key: StringName
@export var evolution_stage: EvolutionStage = EvolutionStage.BABY
@export var base_stats: MonsterStats
@export var visual_scene: PackedScene


static func is_valid_id(id: StringName) -> bool:
	var value := String(id)
	return not value.is_empty() and value.is_valid_identifier() and value == value.to_lower()


# Developer diagnostics; player-facing errors must use translation keys.
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_valid_id(monster_id):
		errors.append("Monster ID must be a nonempty lowercase identifier.")
	if display_name_key.is_empty():
		errors.append("Missing display-name translation key.")
	if evolution_stage < EvolutionStage.BABY or evolution_stage > EvolutionStage.MASTER:
		errors.append("Evolution stage is outside the seven supported stages.")
	if base_stats == null:
		errors.append("Missing base stats.")
	if visual_scene == null:
		errors.append("Missing visual scene.")
	return errors

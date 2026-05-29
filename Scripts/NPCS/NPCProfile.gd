class_name NPCProfile
extends Resource

enum PersonalityType {
	WARM_LOCAL,
	GOSSIP,
	NERVOUS,
	OLD_TIMER,
	BUSY_WORKER,
	STRANGE_REGULAR,
	SUSPICIOUS,
	KID,
	THUG,
	SHOPKEEPER,
	OTHER
}

enum RelationshipTier {
	STRANGER,
	RECOGNISES_PLAYER,
	FRIENDLY,
	TRUSTS_PLAYER,
	STORY_REVEALED
}

enum ServiceType {
	NONE,
	SHOP,
	BATHHOUSE_COUNTER,
	TRAINING,
	QUEST_BOARD,
	INFORMATION,
	OTHER
}

@export_group("Identity")
@export var npc_id: StringName = &""
@export var display_name: String = ""
@export var role: String = ""
@export var personality_type: PersonalityType = PersonalityType.OTHER

@export_group("Dialogue Rules")
@export var dialogue_rules: Array[NPCDialogueRule] = []

@export_group("Fallback Dialogic Timelines")
@export var fallback_timeline: StringName = &""
@export var default_timeline: StringName = &""
@export var first_meeting_timeline: StringName = &""
@export var repeat_timeline: StringName = &""

@export_group("Legacy Time-Based Dialogic Timelines")
@export var morning_timeline: StringName = &""
@export var day_timeline: StringName = &""
@export var evening_timeline: StringName = &""
@export var night_timeline: StringName = &""

@export_group("Legacy Simple Story Override")
@export var story_flag_required: StringName = &""
@export var story_override_timeline: StringName = &""

@export_group("Visual / Model Info - Future Container")
@export var default_model_scene: PackedScene
@export var visual_profile: Resource
@export var portrait_texture: Texture2D
@export_multiline var visual_notes: String = ""

@export_group("Relationship Defaults - Future Container")
@export var starting_relationship_tier: RelationshipTier = RelationshipTier.STRANGER
@export var starting_relationship_points: int = 0
@export var relationship_group: StringName = &""

@export_group("Schedule - Future Container")
@export var schedule_resource: Resource
@export var default_schedule_id: StringName = &""
@export var uses_world_schedule: bool = false

@export_group("Shop / Service - Future Container")
@export var service_type: ServiceType = ServiceType.NONE
@export var service_id: StringName = &""
@export var opens_service_after_dialogue: bool = false


func has_valid_id() -> bool:
	return npc_id != &""


func get_time_timeline(time_block: int) -> StringName:
	match time_block:
		WorldState.TimeBlock.MORNING:
			return morning_timeline
		WorldState.TimeBlock.DAY:
			return day_timeline
		WorldState.TimeBlock.EVENING:
			return evening_timeline
		WorldState.TimeBlock.NIGHT:
			return night_timeline
		_:
			return &""


func get_best_fallback_timeline() -> StringName:
	if fallback_timeline != &"":
		return fallback_timeline

	if default_timeline != &"":
		return default_timeline

	return &""

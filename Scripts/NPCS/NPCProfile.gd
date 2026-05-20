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
	OTHER
}

@export_group("Identity")
@export var npc_id: StringName = &""
@export var display_name: String = ""
@export var role: String = ""
@export var personality_type: PersonalityType = PersonalityType.OTHER

@export_group("Default Dialogic Timelines")
@export var default_timeline: StringName = &""
@export var first_meeting_timeline: StringName = &""
@export var repeat_timeline: StringName = &""

@export_group("Time-Based Dialogic Timelines")
@export var morning_timeline: StringName = &""
@export var day_timeline: StringName = &""
@export var evening_timeline: StringName = &""
@export var night_timeline: StringName = &""

@export_group("Simple Story Override")
@export var story_flag_required: StringName = &""
@export var story_override_timeline: StringName = &""


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

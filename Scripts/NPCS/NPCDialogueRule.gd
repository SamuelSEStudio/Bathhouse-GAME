class_name NPCDialogueRule
extends Resource

enum TimelineSelectionMode {
	FIRST,
	RANDOM
}

@export_group("Rule Identity")
@export var rule_name: String = ""
@export var is_enabled: bool = true
@export var priority: int = 0
@export_multiline var designer_note: String = ""

@export_group("Timeline Pool")
@export var timeline_pool: Array[StringName] = []
@export var selection_mode: TimelineSelectionMode = TimelineSelectionMode.FIRST

@export_group("Talk Count Conditions")
@export var min_talk_count: int = -1
@export var max_talk_count: int = -1

@export_group("Story Flag Conditions")
@export var required_story_flags: Array[StringName] = []
@export var blocked_story_flags: Array[StringName] = []

@export_group("Time Conditions")
@export_flags("Morning", "Day", "Evening", "Night")
var valid_time_blocks_mask: int = 0


func matches(world_state: WorldState, _npc_id: StringName, talk_count: int) -> bool:
	if is_enabled == false:
		return false

	if timeline_pool.is_empty():
		return false

	if _matches_talk_count(talk_count) == false:
		return false

	if _matches_story_flags(world_state) == false:
		return false

	if _matches_time_block(world_state) == false:
		return false

	return true


func choose_timeline() -> StringName:
	if timeline_pool.is_empty():
		return &""

	match selection_mode:
		TimelineSelectionMode.FIRST:
			return timeline_pool[0]

		TimelineSelectionMode.RANDOM:
			var random_index: int = randi_range(0, timeline_pool.size() - 1)
			return timeline_pool[random_index]

		_:
			return timeline_pool[0]


func _matches_talk_count(talk_count: int) -> bool:
	if min_talk_count >= 0 and talk_count < min_talk_count:
		return false

	if max_talk_count >= 0 and talk_count > max_talk_count:
		return false

	return true


func _matches_story_flags(world_state: WorldState) -> bool:
	if world_state == null:
		if required_story_flags.is_empty() == false:
			return false

		return true

	for flag_name: StringName in required_story_flags:
		if world_state.has_story_flag(flag_name) == false:
			return false

	for flag_name: StringName in blocked_story_flags:
		if world_state.has_story_flag(flag_name):
			return false

	return true


func _matches_time_block(world_state: WorldState) -> bool:
	if valid_time_blocks_mask == 0:
		return true

	if world_state == null:
		return false

	var time_block: int = world_state.get_time_block()
	var time_bit: int = 1 << time_block

	return (valid_time_blocks_mask & time_bit) != 0

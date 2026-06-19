class_name NPCDialogueRule
extends Resource

enum TimelineSelectionMode {
	FIRST,
	RANDOM,
	RANDOM_UNSEEN_THEN_RANDOM,
	SEQUENCE
}

@export_group("Rule Identity")
@export var rule_id: StringName = &""
@export var rule_name: String = ""
@export var is_enabled: bool = true
@export var priority: int = 0
@export_multiline var designer_note: String = ""

@export_group("Timeline Pool")
@export var timeline_pool: Array[StringName] = []
@export var selection_mode: TimelineSelectionMode = TimelineSelectionMode.FIRST

@export_group("Sequence Settings")
@export var sequence_loops: bool = false

@export_group("Schedule Conditions")
@export var required_schedule_contexts: Array[StringName] = []
@export var blocked_schedule_contexts: Array[StringName] = []

@export_group("Talk Count Conditions")
@export var min_talk_count: int = -1
@export var max_talk_count: int = -1

@export_group("Story Flag Conditions")
@export var required_story_flags: Array[StringName] = []
@export var blocked_story_flags: Array[StringName] = []

@export_group("Time Conditions")
@export_flags("Morning", "Day", "Evening", "Night")
var valid_time_blocks_mask: int = 0


func matches(
	world_state: WorldState,
	_npc_id: StringName,
	talk_count: int,
	schedule_contexts: Array[StringName] = []
) -> bool:
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

	if _matches_schedule_contexts(schedule_contexts) == false:
		return false

	return true


func choose_timeline(world_state: WorldState, npc_id: StringName) -> StringName:
	if timeline_pool.is_empty():
		return &""

	match selection_mode:
		TimelineSelectionMode.FIRST:
			return _choose_first()

		TimelineSelectionMode.RANDOM:
			return _choose_random()

		TimelineSelectionMode.RANDOM_UNSEEN_THEN_RANDOM:
			return _choose_random_unseen_then_random(world_state, npc_id)

		TimelineSelectionMode.SEQUENCE:
			return _choose_sequence(world_state, npc_id)

		_:
			return _choose_first()


func get_memory_rule_id() -> StringName:
	if rule_id != &"":
		return rule_id

	if resource_path != "":
		return StringName(resource_path)

	if rule_name != "":
		return _normalise_rule_id(rule_name)

	return &"unnamed_dialogue_rule"


func _choose_first() -> StringName:
	return timeline_pool[0]


func _choose_random() -> StringName:
	var random_index: int = randi_range(0, timeline_pool.size() - 1)
	return timeline_pool[random_index]


func _choose_random_unseen_then_random(world_state: WorldState, npc_id: StringName) -> StringName:
	if world_state == null or npc_id == &"":
		return _choose_random()

	var memory_rule_id: StringName = get_memory_rule_id()
	var unseen_timelines: Array[StringName] = world_state.get_unseen_dialogue_rule_timelines(
		npc_id,
		memory_rule_id,
		timeline_pool
	)

	var selected_timeline: StringName = &""

	if unseen_timelines.is_empty():
		selected_timeline = _choose_random()
	else:
		var random_index: int = randi_range(0, unseen_timelines.size() - 1)
		selected_timeline = unseen_timelines[random_index]

	world_state.mark_dialogue_rule_timeline_seen(npc_id, memory_rule_id, selected_timeline)
	return selected_timeline


func _choose_sequence(world_state: WorldState, npc_id: StringName) -> StringName:
	if world_state == null or npc_id == &"":
		return _choose_first()

	var memory_rule_id: StringName = get_memory_rule_id()
	var sequence_index: int = world_state.get_dialogue_rule_sequence_index(npc_id, memory_rule_id)

	if sequence_loops:
		sequence_index = sequence_index % timeline_pool.size()
	else:
		sequence_index = clampi(sequence_index, 0, timeline_pool.size() - 1)

	var selected_timeline: StringName = timeline_pool[sequence_index]

	world_state.advance_dialogue_rule_sequence_index(
		npc_id,
		memory_rule_id,
		timeline_pool.size(),
		sequence_loops
	)

	return selected_timeline


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


func _matches_schedule_contexts(schedule_contexts: Array[StringName]) -> bool:
	for required_context: StringName in required_schedule_contexts:
		if schedule_contexts.has(required_context) == false:
			return false

	for blocked_context: StringName in blocked_schedule_contexts:
		if schedule_contexts.has(blocked_context):
			return false

	return true


func _normalise_rule_id(value: String) -> StringName:
	var normalised: String = value.strip_edges().to_lower()
	normalised = normalised.replace(" ", "_")
	normalised = normalised.replace("-", "_")
	return StringName(normalised)

class_name WorldState
extends Node

enum TimeBlock {
	MORNING,
	DAY,
	EVENING,
	NIGHT
}

signal time_block_changed(new_time_block: int)
signal story_flag_changed(flag_name: StringName, enabled: bool)
signal npc_met_changed(npc_id: StringName, has_met: bool)
signal npc_talk_count_changed(npc_id: StringName, talk_count: int)

signal npc_dialogue_rule_timeline_seen(npc_id: StringName, rule_id: StringName, timeline_name: StringName)
signal npc_dialogue_rule_sequence_changed(npc_id: StringName, rule_id: StringName, sequence_index: int)

@export var starting_time_block: TimeBlock = TimeBlock.DAY

var current_time_block: int = TimeBlock.DAY
var story_flags: Dictionary = {}
var met_npcs: Dictionary = {}
var npc_talk_counts: Dictionary = {}

var npc_dialogue_rule_seen_timelines: Dictionary = {}
var npc_dialogue_rule_sequence_indexes: Dictionary = {}


func _ready() -> void:
	current_time_block = int(starting_time_block)


func set_time_block(new_time_block: int) -> void:
	if current_time_block == new_time_block:
		return

	current_time_block = new_time_block
	time_block_changed.emit(current_time_block)


func get_current_time_block() -> int:
	return current_time_block


func get_time_block_name() -> StringName:
	match current_time_block:
		TimeBlock.MORNING:
			return &"morning"
		TimeBlock.DAY:
			return &"day"
		TimeBlock.EVENING:
			return &"evening"
		TimeBlock.NIGHT:
			return &"night"
		_:
			return &"unknown"


func set_story_flag(flag_name: StringName, enabled: bool = true) -> void:
	if flag_name == &"":
		return

	story_flags[flag_name] = enabled
	story_flag_changed.emit(flag_name, enabled)


func has_story_flag(flag_name: StringName) -> bool:
	if flag_name == &"":
		return false

	if story_flags.has(flag_name) == false:
		return false

	return bool(story_flags[flag_name])


func clear_story_flag(flag_name: StringName) -> void:
	if flag_name == &"":
		return

	story_flags[flag_name] = false
	story_flag_changed.emit(flag_name, false)


func mark_npc_met(npc_id: StringName) -> void:
	if npc_id == &"":
		return

	if has_met_npc(npc_id):
		return

	met_npcs[npc_id] = true
	npc_met_changed.emit(npc_id, true)


func has_met_npc(npc_id: StringName) -> bool:
	if npc_id == &"":
		return false

	if met_npcs.has(npc_id) == false:
		return false

	return bool(met_npcs[npc_id])


func increment_npc_talk_count(npc_id: StringName) -> int:
	if npc_id == &"":
		return 0

	var current_count: int = get_npc_talk_count(npc_id)
	current_count += 1
	npc_talk_counts[npc_id] = current_count
	npc_talk_count_changed.emit(npc_id, current_count)

	return current_count


func get_npc_talk_count(npc_id: StringName) -> int:
	if npc_id == &"":
		return 0

	if npc_talk_counts.has(npc_id) == false:
		return 0

	return int(npc_talk_counts[npc_id])


func mark_dialogue_rule_timeline_seen(npc_id: StringName, rule_id: StringName, timeline_name: StringName) -> void:
	if npc_id == &"" or rule_id == &"" or timeline_name == &"":
		return

	var memory_key: String = _get_dialogue_rule_memory_key(npc_id, rule_id)
	var seen_timelines: Array[StringName] = get_seen_dialogue_rule_timelines(npc_id, rule_id)

	if seen_timelines.has(timeline_name):
		return

	seen_timelines.append(timeline_name)
	npc_dialogue_rule_seen_timelines[memory_key] = seen_timelines
	npc_dialogue_rule_timeline_seen.emit(npc_id, rule_id, timeline_name)


func has_seen_dialogue_rule_timeline(npc_id: StringName, rule_id: StringName, timeline_name: StringName) -> bool:
	if npc_id == &"" or rule_id == &"" or timeline_name == &"":
		return false

	var seen_timelines: Array[StringName] = get_seen_dialogue_rule_timelines(npc_id, rule_id)
	return seen_timelines.has(timeline_name)


func get_seen_dialogue_rule_timelines(npc_id: StringName, rule_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []

	if npc_id == &"" or rule_id == &"":
		return result

	var memory_key: String = _get_dialogue_rule_memory_key(npc_id, rule_id)

	if npc_dialogue_rule_seen_timelines.has(memory_key) == false:
		return result

	var stored_value: Variant = npc_dialogue_rule_seen_timelines[memory_key]

	if stored_value is Array:
		var stored_array: Array = stored_value as Array
		for item: Variant in stored_array:
			result.append(StringName(String(item)))

	return result


func get_unseen_dialogue_rule_timelines(
	npc_id: StringName,
	rule_id: StringName,
	timeline_pool: Array[StringName]
) -> Array[StringName]:
	var result: Array[StringName] = []

	if npc_id == &"" or rule_id == &"":
		return result

	for timeline_name: StringName in timeline_pool:
		if has_seen_dialogue_rule_timeline(npc_id, rule_id, timeline_name) == false:
			result.append(timeline_name)

	return result


func reset_dialogue_rule_seen_timelines(npc_id: StringName, rule_id: StringName) -> void:
	if npc_id == &"" or rule_id == &"":
		return

	var memory_key: String = _get_dialogue_rule_memory_key(npc_id, rule_id)
	npc_dialogue_rule_seen_timelines.erase(memory_key)


func get_dialogue_rule_sequence_index(npc_id: StringName, rule_id: StringName) -> int:
	if npc_id == &"" or rule_id == &"":
		return 0

	var memory_key: String = _get_dialogue_rule_memory_key(npc_id, rule_id)

	if npc_dialogue_rule_sequence_indexes.has(memory_key) == false:
		return 0

	return int(npc_dialogue_rule_sequence_indexes[memory_key])


func set_dialogue_rule_sequence_index(npc_id: StringName, rule_id: StringName, sequence_index: int) -> void:
	if npc_id == &"" or rule_id == &"":
		return

	var safe_index: int = max(sequence_index, 0)
	var memory_key: String = _get_dialogue_rule_memory_key(npc_id, rule_id)

	npc_dialogue_rule_sequence_indexes[memory_key] = safe_index
	npc_dialogue_rule_sequence_changed.emit(npc_id, rule_id, safe_index)


func advance_dialogue_rule_sequence_index(
	npc_id: StringName,
	rule_id: StringName,
	timeline_count: int,
	loops: bool
) -> int:
	if npc_id == &"" or rule_id == &"":
		return 0

	if timeline_count <= 0:
		return 0

	var current_index: int = get_dialogue_rule_sequence_index(npc_id, rule_id)
	var next_index: int = current_index + 1

	if loops:
		next_index = next_index % timeline_count
	else:
		next_index = min(next_index, timeline_count - 1)

	set_dialogue_rule_sequence_index(npc_id, rule_id, next_index)
	return next_index


func reset_dialogue_rule_sequence_index(npc_id: StringName, rule_id: StringName) -> void:
	if npc_id == &"" or rule_id == &"":
		return

	var memory_key: String = _get_dialogue_rule_memory_key(npc_id, rule_id)
	npc_dialogue_rule_sequence_indexes.erase(memory_key)
	npc_dialogue_rule_sequence_changed.emit(npc_id, rule_id, 0)


func _get_dialogue_rule_memory_key(npc_id: StringName, rule_id: StringName) -> String:
	return "%s::%s" % [String(npc_id), String(rule_id)]

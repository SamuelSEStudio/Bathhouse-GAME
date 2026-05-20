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

@export var starting_time_block: TimeBlock = TimeBlock.DAY

var current_time_block: int = TimeBlock.DAY
var story_flags: Dictionary = {}
var met_npcs: Dictionary = {}
var npc_talk_counts: Dictionary = {}


func _ready() -> void:
	current_time_block = int(starting_time_block)


func set_time_block(new_time_block: int) -> void:
	if current_time_block == new_time_block:
		return

	current_time_block = new_time_block
	time_block_changed.emit(current_time_block)


func get_time_block() -> int:
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

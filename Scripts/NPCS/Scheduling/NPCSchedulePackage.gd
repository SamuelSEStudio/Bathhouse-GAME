class_name NPCSchedulePackage
extends Resource

enum SpawnMode {
	IN_WORLD,
	HIDDEN,
	OFFSCREEN
}

@export_group("Package Identity")
@export var package_id: StringName = &""
@export var display_name: String = ""
@export var priority: int = 0
@export_multiline var designer_note: String = ""

@export_group("Time Block")
@export_flags("Morning", "Day", "Evening", "Night")
var valid_time_blocks_mask: int = 0

@export_group("World Placement")
@export var location_id: StringName = &""
@export var spawn_mode: SpawnMode = SpawnMode.IN_WORLD
@export var snap_to_marker: bool = true

@export_group("Activity")
@export var activity_id: StringName = &""
@export var idle_animation: StringName = &""
@export var schedule_contexts: Array[StringName] = []

@export_group("Interaction")
@export var can_interact: bool = true
@export var service_available: bool = true

@export_group("Future Story Conditions")
@export var required_story_flags: Array[StringName] = []
@export var blocked_story_flags: Array[StringName] = []

@export_group("Future Quest Hooks")
@export var required_quest_state: StringName = &""
@export var blocked_quest_state: StringName = &""

@export_group("Future Encounter Hooks")
@export var encounter_id: StringName = &""
@export var can_trigger_encounter: bool = false


func matches(world_state: WorldState, time_block: int) -> bool:
	if _matches_time_block(time_block) == false:
		return false

	if _matches_story_flags(world_state) == false:
		return false

	if _matches_future_quest_state() == false:
		return false

	return true


func is_visible_in_world() -> bool:
	return spawn_mode == SpawnMode.IN_WORLD


func has_context(context_id: StringName) -> bool:
	return schedule_contexts.has(context_id)


func allows_service() -> bool:
	return service_available and spawn_mode == SpawnMode.IN_WORLD


func allows_interaction() -> bool:
	return can_interact and spawn_mode == SpawnMode.IN_WORLD


func _matches_time_block(time_block: int) -> bool:
	if valid_time_blocks_mask == 0:
		return true

	var time_bit: int = 1 << time_block
	return (valid_time_blocks_mask & time_bit) != 0


func _matches_story_flags(world_state: WorldState) -> bool:
	if world_state == null:
		return true

	for flag_name: StringName in required_story_flags:
		if world_state.has_story_flag(flag_name) == false:
			return false

	for flag_name: StringName in blocked_story_flags:
		if world_state.has_story_flag(flag_name):
			return false

	return true


func _matches_future_quest_state() -> bool:
	# Placeholder for later quest integration.
	# Future example:
	# return QuestManager.matches_required_state(required_quest_state, blocked_quest_state)
	return true


func get_debug_label() -> String:
	if display_name != "":
		return display_name

	if package_id != &"":
		return String(package_id)

	return "Unnamed Schedule Package"

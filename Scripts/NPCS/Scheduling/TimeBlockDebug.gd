@tool
class_name TimeBlockDebugControls
extends Node

@export_group("Debug Time Controls")
@export_tool_button("Set Morning")
var set_morning_button: Callable = _set_morning

@export_tool_button("Set Day")
var set_day_button: Callable = _set_day

@export_tool_button("Set Evening")
var set_evening_button: Callable = _set_evening

@export_tool_button("Set Night")
var set_night_button: Callable = _set_night

@export_tool_button("Refresh NPC Schedules")
var refresh_schedules_button: Callable = _refresh_all_npc_schedules


func _set_morning() -> void:
	_set_time_block(WorldState.TimeBlock.MORNING)


func _set_day() -> void:
	_set_time_block(WorldState.TimeBlock.DAY)


func _set_evening() -> void:
	_set_time_block(WorldState.TimeBlock.EVENING)


func _set_night() -> void:
	_set_time_block(WorldState.TimeBlock.NIGHT)


func _set_time_block(time_block: int) -> void:
	var world_state: WorldState = _get_world_state()

	if world_state == null:
		push_warning("TimeBlockDebugControls could not find WorldState.")
		return

	world_state.set_time_block(time_block)
	_refresh_all_npc_schedules()

	print("Debug time block set to: %s" % _get_time_block_label(time_block))


func _refresh_all_npc_schedules() -> void:
	if get_tree() == null:
		return

	var npcs: Array[Node] = get_tree().get_nodes_in_group("npcs")

	for npc_node: Node in npcs:
		var npc: NPCBase = npc_node as NPCBase

		if npc == null:
			continue

		npc.refresh_schedule()

	print("Refreshed %s NPC schedules." % str(npcs.size()))


func _get_world_state() -> WorldState:
	if Engine.is_editor_hint():
		var root: Window = EditorInterface.get_base_control().get_tree().root
		return root.get_node_or_null("World_State") as WorldState

	var root: Window = get_tree().root

	var world_state: WorldState = root.get_node_or_null("World_State") as WorldState

	if world_state != null:
		return world_state

	world_state = root.get_node_or_null("World_state") as WorldState

	if world_state != null:
		return world_state

	return root.get_node_or_null("WorldStateGlobal") as WorldState


func _get_time_block_label(time_block: int) -> String:
	match time_block:
		WorldState.TimeBlock.MORNING:
			return "Morning"
		WorldState.TimeBlock.DAY:
			return "Day"
		WorldState.TimeBlock.EVENING:
			return "Evening"
		WorldState.TimeBlock.NIGHT:
			return "Night"
		_:
			return "Unknown"

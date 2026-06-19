class_name TimeBlockRuntimeDebug
extends Node

@export var enabled: bool = true
@export var print_debug: bool = true

@export_group("Keyboard Shortcuts")
@export var morning_key: Key = KEY_1
@export var day_key: Key = KEY_2
@export var evening_key: Key = KEY_3
@export var night_key: Key = KEY_4
@export var refresh_key: Key = KEY_5


func _unhandled_input(event: InputEvent) -> void:
	if enabled == false:
		return

	var key_event: InputEventKey = event as InputEventKey

	if key_event == null:
		return

	if key_event.pressed == false:
		return

	if key_event.echo:
		return

	match key_event.keycode:
		morning_key:
			_set_time_block(WorldState.TimeBlock.MORNING)
			get_viewport().set_input_as_handled()

		day_key:
			_set_time_block(WorldState.TimeBlock.DAY)
			get_viewport().set_input_as_handled()

		evening_key:
			_set_time_block(WorldState.TimeBlock.EVENING)
			get_viewport().set_input_as_handled()

		night_key:
			_set_time_block(WorldState.TimeBlock.NIGHT)
			get_viewport().set_input_as_handled()

		refresh_key:
			_refresh_all_npc_schedules()
			get_viewport().set_input_as_handled()


func _set_time_block(time_block: int) -> void:
	var world_state: WorldState = _get_world_state()

	if world_state == null:
		push_warning("TimeBlockRuntimeDebug could not find /root/World_State.")
		_print_runtime_root_children()
		return

	world_state.set_time_block(time_block)
	_refresh_all_npc_schedules()

	if print_debug:
		print("Runtime debug time block set to: %s" % _get_time_block_label(time_block))


func _refresh_all_npc_schedules() -> void:
	var npcs: Array[Node] = get_tree().get_nodes_in_group("npcs")
	var refreshed_count: int = 0

	for npc_node: Node in npcs:
		var npc: NPCBase = npc_node as NPCBase

		if npc == null:
			continue

		npc.refresh_schedule()
		refreshed_count += 1

		if npc.has_method("_debug_print_schedule"):
			npc.call("_debug_print_schedule")

	if print_debug:
		print("Runtime refreshed %s NPC schedules from %s nodes in group 'npcs'." % [str(refreshed_count), str(npcs.size())])


func _get_world_state() -> WorldState:
	return get_node_or_null("/root/World_State") as WorldState


func _print_runtime_root_children() -> void:
	print("Runtime root children:")

	for child: Node in get_tree().root.get_children():
		print("- %s | %s" % [child.name, child.get_class()])


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

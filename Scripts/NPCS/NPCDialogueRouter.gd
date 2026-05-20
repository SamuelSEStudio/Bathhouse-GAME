class_name NPCDialogueRouter
extends RefCounted


static func get_timeline(profile: NPCProfile, fallback_timeline: StringName = &"") -> StringName:
	if profile == null:
		return fallback_timeline

	var world_state: WorldState = _get_world_state()

	if world_state != null:
		if profile.story_flag_required != &"" and profile.story_override_timeline != &"":
			if world_state.has_story_flag(profile.story_flag_required):
				return profile.story_override_timeline

		if profile.npc_id != &"":
			if world_state.has_met_npc(profile.npc_id) == false:
				if profile.first_meeting_timeline != &"":
					return profile.first_meeting_timeline

		var time_timeline: StringName = profile.get_time_timeline(world_state.get_time_block())
		if time_timeline != &"":
			return time_timeline

	if profile.repeat_timeline != &"":
		return profile.repeat_timeline

	if profile.default_timeline != &"":
		return profile.default_timeline

	return fallback_timeline


static func _get_world_state() -> WorldState:
	var main_loop: MainLoop = Engine.get_main_loop()
	var scene_tree: SceneTree = main_loop as SceneTree

	if scene_tree == null:
		return null

	var node: Node = scene_tree.root.get_node_or_null("World_State")
	return node as WorldState

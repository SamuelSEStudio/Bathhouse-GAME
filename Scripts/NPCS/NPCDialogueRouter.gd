class_name NPCDialogueRouter
extends RefCounted


static func get_timeline_for_npc(npc: NPCBase, fallback_timeline: StringName = &"") -> StringName:
	if npc == null:
		return fallback_timeline

	return get_timeline(
		npc.npc_profile,
		fallback_timeline,
		npc.current_schedule_contexts
	)


static func get_timeline(
	profile: NPCProfile,
	fallback_timeline: StringName = &"",
	schedule_contexts: Array[StringName] = []
) -> StringName:
	if profile == null:
		return fallback_timeline

	var world_state: WorldState = _get_world_state()
	var talk_count: int = _get_talk_count(profile, world_state)

	var rule_timeline: StringName = _get_rule_timeline(
		profile,
		world_state,
		talk_count,
		schedule_contexts
	)

	if rule_timeline != &"":
		return rule_timeline

	var legacy_timeline: StringName = _get_legacy_timeline(profile, world_state, talk_count)
	if legacy_timeline != &"":
		return legacy_timeline

	return fallback_timeline


static func _get_rule_timeline(
	profile: NPCProfile,
	world_state: WorldState,
	talk_count: int,
	schedule_contexts: Array[StringName]
) -> StringName:
	if profile.dialogue_rules.is_empty():
		return &""

	var sorted_rules: Array[NPCDialogueRule] = []

	for rule: NPCDialogueRule in profile.dialogue_rules:
		if rule != null:
			sorted_rules.append(rule)

	sorted_rules.sort_custom(_sort_rules_by_priority)

	for rule: NPCDialogueRule in sorted_rules:
		if rule.matches(world_state, profile.npc_id, talk_count, schedule_contexts):
			return rule.choose_timeline(world_state, profile.npc_id)

	return &""


static func _sort_rules_by_priority(a: NPCDialogueRule, b: NPCDialogueRule) -> bool:
	return a.priority > b.priority


static func _get_legacy_timeline(profile: NPCProfile, world_state: WorldState, talk_count: int) -> StringName:
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

	if talk_count > 0 and profile.repeat_timeline != &"":
		return profile.repeat_timeline

	if profile.default_timeline != &"":
		return profile.default_timeline

	return profile.get_best_fallback_timeline()


static func _get_talk_count(profile: NPCProfile, world_state: WorldState) -> int:
	if profile == null:
		return 0

	if world_state == null:
		return 0

	if profile.npc_id == &"":
		return 0

	return world_state.get_npc_talk_count(profile.npc_id)


static func _get_world_state() -> WorldState:
	var main_loop: MainLoop = Engine.get_main_loop()
	var scene_tree: SceneTree = main_loop as SceneTree

	if scene_tree == null:
		return null

	var node: Node = scene_tree.root.get_node_or_null("World_State")
	return node as WorldState

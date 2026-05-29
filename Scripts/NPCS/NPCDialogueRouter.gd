class_name NPCDialogueRouter
extends RefCounted


static func get_timeline(profile: NPCProfile, fallback_timeline: StringName = &"") -> StringName:
	if profile == null:
		return fallback_timeline

	var world_state: WorldState = _get_world_state()
	var talk_count: int = _get_talk_count(profile, world_state)

	var rule_timeline: StringName = _get_rule_timeline(profile, world_state, talk_count)
	if rule_timeline != &"":
		return rule_timeline

	var legacy_timeline: StringName = _get_legacy_timeline(profile, world_state, talk_count)
	if legacy_timeline != &"":
		return legacy_timeline

	return fallback_timeline


static func _get_rule_timeline(profile: NPCProfile, world_state: WorldState, talk_count: int) -> StringName:
	if profile.dialogue_rules.is_empty():
		return &""

	var sorted_rules: Array[NPCDialogueRule] = profile.dialogue_rules.duplicate()
	sorted_rules.sort_custom(_sort_rules_by_priority)

	for rule: NPCDialogueRule in sorted_rules:
		if rule == null:
			continue

		if rule.matches(world_state, profile.npc_id, talk_count):
			return rule.choose_timeline()

	return &""


static func _sort_rules_by_priority(a: NPCDialogueRule, b: NPCDialogueRule) -> bool:
	if a == null:
		return false

	if b == null:
		return true

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

	var possible_names: Array[StringName] = [
		&"World_State",
		&"World_state",
		&"WorldStateGlobal"
	]

	for autoload_name: StringName in possible_names:
		var node: Node = scene_tree.root.get_node_or_null(String(autoload_name))
		if node is WorldState:
			return node as WorldState

	return null

extends Node

enum Mode {
	EXPLORATION,
	PRACTICE,
	COMBAT
}

var mode: int = Mode.EXPLORATION

var active_dialogue_npc: NPCBase = null
var active_dialogue_timeline: StringName = &""


func _ready() -> void:
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended) == false:
		Dialogic.timeline_ended.connect(_on_timeline_ended)


func _on_timeline_ended() -> void:
	if mode == Mode.EXPLORATION:
		set_player_cam()

	end_npc_dialogue()


func begin_npc_dialogue(npc: NPCBase, timeline_name: StringName = &"") -> void:
	active_dialogue_npc = npc
	active_dialogue_timeline = timeline_name


func end_npc_dialogue() -> void:
	active_dialogue_npc = null
	active_dialogue_timeline = &""

func get_active_dialogue_npc() -> NPCBase:
	if active_dialogue_npc == null:
		return null

	if is_instance_valid(active_dialogue_npc) == false:
		active_dialogue_npc = null
		return null

	return active_dialogue_npc

func is_in_practice() -> bool:
	return mode == Mode.PRACTICE


func enter_practice(player: Player, side_cam_name: String) -> void:
	mode = Mode.PRACTICE
	player.in_fight = true
	change_cinematic_cam(side_cam_name)
	player.enter_practice()


func exit_practice() -> void:
	mode = Mode.EXPLORATION

	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return

	player.in_fight = false
	player.exit_practice()
	player.set_default_cam()


func change_cinematic_cam(camera_name: String) -> void:
	var all_cinematic_cams: Array[Node] = get_tree().get_nodes_in_group("cinematic_cams")

	for cam: Node in all_cinematic_cams:
		if cam.name == camera_name:
			if cam.has_method("activate"):
				cam.call("activate")
			elif cam is Camera3D:
				var camera: Camera3D = cam as Camera3D
				camera.make_current()
			return

	push_warning("No cinematic camera found with name: %s" % camera_name)


# New Dialogic camera function.
# Use this in timelines from now on:
# do GameManager.change_dialogue_cam("player")
# do GameManager.change_dialogue_cam("npc")
# do GameManager.change_dialogue_cam("npc_close")
# do GameManager.change_dialogue_cam("npc_side")
# do GameManager.change_dialogue_cam("npc_dramatic")
func change_dialogue_cam(target_name: String = "npc", camera_slot: String = "default") -> void:
	var clean_target: String = target_name.strip_edges().to_lower()
	var selected_slot: StringName = StringName(camera_slot.strip_edges().to_lower())

	if clean_target == "":
		_set_active_npc_camera(&"default")
		return

	if clean_target == "player":
		_set_player_selfie_camera()
		return

	if clean_target == "npc" or clean_target == "active_npc":
		_set_active_npc_camera(selected_slot)
		return

	if clean_target.begins_with("npc_"):
		var slot_text: String = clean_target.substr(4)
		_set_active_npc_camera(StringName(slot_text))
		return

	push_warning("Unknown dialogue camera target: %s" % target_name)


# Legacy wrapper.
# Old timelines can still call:
# do GameManager.change_selfie_cam("Fisherman")
# But this no longer searches every NPC by name.
# It only routes to the active NPC if that active NPC matches the name.
func change_selfie_cam(npc_name: String) -> void:
	var clean_name: String = npc_name.strip_edges().to_lower()

	if clean_name == "player":
		change_dialogue_cam("player")
		return

	if clean_name == "" or clean_name == "npc" or clean_name == "active_npc":
		change_dialogue_cam("npc")
		return

	if _active_npc_matches_name(npc_name):
		change_dialogue_cam("npc")
		return

	push_warning("Legacy change_selfie_cam could not find active NPC matching: %s" % npc_name)


func set_player_cam() -> void:
	var player: Player = get_tree().get_first_node_in_group("player") as Player

	if player == null:
		return

	player.set_default_cam()


func play_anim(target_name: String, anim_name: String) -> void:
	var target: Node = _get_dialogue_target(target_name)

	if target == null:
		push_warning("Could not play animation. No dialogue target found: %s" % target_name)
		return

	if target.has_method("play_animation") == false:
		push_warning("Dialogue target has no play_animation method: %s" % target.name)
		return

	target.call("play_animation", anim_name)


func _set_active_npc_camera(camera_slot: StringName = &"default") -> void:
	if active_dialogue_npc == null:
		push_warning("No active dialogue NPC. Could not switch to NPC camera: %s" % String(camera_slot))
		return

	if is_instance_valid(active_dialogue_npc) == false:
		active_dialogue_npc = null
		push_warning("Active dialogue NPC is no longer valid.")
		return

	var did_switch: bool = active_dialogue_npc.set_dialogue_cam(camera_slot)

	if did_switch == false and camera_slot != &"default":
		active_dialogue_npc.set_dialogue_cam(&"default")


func _set_player_selfie_camera() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")

	if player == null:
		push_warning("No player found in group 'player'.")
		return

	if player.has_method("set_selfie_cam") == false:
		push_warning("Player has no set_selfie_cam method.")
		return

	player.call("set_selfie_cam")


func _get_dialogue_target(target_name: String) -> Node:
	var clean_name: String = target_name.strip_edges().to_lower()

	if clean_name == "player":
		return get_tree().get_first_node_in_group("player")

	if clean_name == "" or clean_name == "npc" or clean_name == "active_npc":
		return active_dialogue_npc

	if _active_npc_matches_name(target_name):
		return active_dialogue_npc

	return null


func _active_npc_matches_name(search_name: String) -> bool:
	if active_dialogue_npc == null:
		return false

	if is_instance_valid(active_dialogue_npc) == false:
		return false

	var search_key: String = _normalise_dialogue_key(search_name)

	if _normalise_dialogue_key(active_dialogue_npc.name) == search_key:
		return true

	if active_dialogue_npc.npc_profile == null:
		return false

	if _normalise_dialogue_key(String(active_dialogue_npc.npc_profile.npc_id)) == search_key:
		return true

	if _normalise_dialogue_key(active_dialogue_npc.npc_profile.display_name) == search_key:
		return true

	return false


func _normalise_dialogue_key(value: String) -> String:
	return value.strip_edges().to_lower().replace(" ", "").replace("_", "").replace("-", "")

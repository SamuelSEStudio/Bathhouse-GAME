extends Node

var return_scene_path: String = ""
var return_player_xform: Transform3D
var prompt_every_sec: float = 60.0

# NEW
var current_entrance_id: StringName = &""
var disabled_entrances: Dictionary = {} # StringName -> bool

func is_entrance_disabled(id: StringName) -> bool:
	return disabled_entrances.get(id, false) == true

func disable_entrance(id: StringName) -> void:
	if id != &"":
		disabled_entrances[id] = true

func enter_training(
	practice_scene_path: String,
	player_xform: Transform3D,
	p_prompt_every_sec: float,
	entrance_id: StringName
) -> void:
	return_scene_path = get_tree().current_scene.scene_file_path
	return_player_xform = player_xform
	prompt_every_sec = p_prompt_every_sec
	current_entrance_id = entrance_id

	get_tree().change_scene_to_file(practice_scene_path)

func exit_training() -> void:
	# NEW: permanently disable the entrance that started this training
	disable_entrance(current_entrance_id)
	current_entrance_id = &""

	if return_scene_path == "":
		return

	get_tree().change_scene_to_file(return_scene_path)
	await get_tree().process_frame

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		player.global_transform = return_player_xform

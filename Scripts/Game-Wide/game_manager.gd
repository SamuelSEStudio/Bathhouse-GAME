extends Node

enum Mode {EXPLORATION, PRACTICE, COMBAT}
var mode: int = Mode.EXPLORATION


func _ready()-> void:
	Dialogic.timeline_ended.connect(_on_timeline_ended)

func _on_timeline_ended() -> void:
	if mode == Mode.EXPLORATION:
		set_player_cam()
		
func is_in_practice() -> bool:
	return mode == Mode.PRACTICE
	
func enter_practice(player: Player, side_cam_name: String) -> void:
	mode = Mode.PRACTICE
	player.in_fight = true
	change_cinematic_cam(side_cam_name)
	player.enter_practice()
	
func exit_practice() -> void:
	mode = Mode.EXPLORATION
	var player: Player =get_tree().get_first_node_in_group("player")
	if player:
		player.in_fight = false
		player.exit_practice()
		player.set_default_cam()
	
func change_cinematic_cam(camera_name: String) -> void:
	var all_cinematic_cams:Array = get_tree().get_nodes_in_group("cinematic_cams")
	for cam in all_cinematic_cams:
		if cam.name == camera_name:
			cam.activate()
#changes camera to the npcs or players selfie cam through dialogic
func change_selfie_cam(npc_name:String) -> void:
	var npc:Node3D
	var all_npcs:Array = get_tree().get_nodes_in_group("npcs")
	if npc_name == "Player":
		npc = get_tree().get_first_node_in_group("player")
	else:
		for _npc in all_npcs:
			if _npc.name == npc_name:
				npc = _npc
				
	npc.set_selfie_cam()
#changes camera back to players default at end of timeline.
func set_player_cam():
	var player:Player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_default_cam()
		
func play_anim(npc_name:String, anim_name:String) -> void:
	var npc:Node3D
	var all_npcs:Array = get_tree().get_nodes_in_group("npcs")
	if npc_name == "Player":
		npc = get_tree().get_first_node_in_group("player")
	else:
		for _npc in all_npcs:
			if _npc.name == npc_name:
				npc = _npc
				
	npc.play_animation(anim_name)

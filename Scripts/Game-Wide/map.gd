extends Node3D

@export var practice_timeline:= "Train_Park"
@export var side_cam_name := "Cinematic_Cam2"

var _armed:= true
var _cached_player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_can_train_body_entered(body: Node3D) -> void:
	if not _armed: return
	if body is Player:
		_armed = false
		_cached_player = body
		Dialogic.start_timeline(practice_timeline)
		await Dialogic.timeline_ended
		on_practice_cutscene_done()
		
func on_practice_cutscene_done() -> void:
	var next_level_path = "res://Scenes/Levels/world_park_practice.tscn"
	get_tree().change_scene_to_file(next_level_path)
	#GameManager.enter_practice(_cached_player,side_cam_name)


func _on_can_train_body_exited(body: Node3D) -> void:
	if body is Player and GameManager.is_in_practice():
		GameManager.exit_practice()
		_armed=true

extends Node3D

@export var side_cam_name := "Fight_Cam-2D"
var _cached_player: Player
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_can_fight_body_entered(body: Node3D) -> void:
	if body is Player:
		_cached_player = body
		_lets_fight()
	
func _lets_fight()->void:
	GameManager.enter_practice(_cached_player,side_cam_name)

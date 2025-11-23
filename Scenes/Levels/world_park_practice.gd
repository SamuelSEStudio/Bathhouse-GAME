extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CameraShake_Loader.register_camera($"Fight_Cam-2D")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

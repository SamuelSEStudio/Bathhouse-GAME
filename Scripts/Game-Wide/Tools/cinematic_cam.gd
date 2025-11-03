extends Camera3D

class_name CinematicCam
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("cinematic_cams")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#can do lerps etc process positions wait a frame
	
func activate():
	set_current(true)
	

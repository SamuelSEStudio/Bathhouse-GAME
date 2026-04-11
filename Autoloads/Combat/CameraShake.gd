extends Node
class_name CameraShake

@export var cam_path: NodePath
var _cam: Camera3D
var _original_transform: Transform3D
var _time: float = 0.0
var _duration: float = 0.0
var _magnitude: float = 0.0

func _ready() -> void:
	_cam = get_node_or_null(cam_path) as Camera3D
	if _cam != null:
		_original_transform = _cam.transform
		
func register_camera(cam: Camera3D) -> void:
	_cam = cam
	if _cam != null:
		_original_transform = _cam.transform

func kick(duration: float = 0.08, magnitude: float = 0.05) -> void:
	_duration = duration
	_magnitude = magnitude
	_time = 0.0
	if _cam == null:
		return
	_original_transform = _cam.transform
	set_process(true)

func _process(delta: float) -> void:
	if _cam == null:
		set_process(false)
		return
	_time += delta
	var t: float = min(1.0, _time / _duration)
	var damp: float = 1.0 - t
	var offset := Vector3(
		(randf() * 2.0 - 1.0) * _magnitude * damp,
		(randf() * 2.0 - 1.0) * _magnitude * damp,
		0.0
	)
	_cam.transform = _original_transform.translated(offset)
	if t >= 1.0:
		_cam.transform = _original_transform
		set_process(false)

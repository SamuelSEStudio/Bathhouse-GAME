extends Node
class_name ComboInput

var _camera_ref: Camera3D
@export var visuals: Node3D                         # player.visuals
enum AxisLocal { X = 0, Z_NEG = 1 }
@export var visuals_forward_axis: AxisLocal = AxisLocal.X
@export_range(0.1, 1.0, 0.05) var ff_window: float = 0.50
@export_range(0.1, 1.5, 0.05) var clear_window: float = 0.70
@export_range(0.1, 1.0, 0.05) var tap_grace: float = 0.35  # window for sequences
#--------Attack states--------#
@export var jab_state: State                  # neutral Punch
@export var straight_state: State             # F Punch
@export var neutral_kick_state: State         # neutral Kick
@export var front_kick_state: State
@export var back_kick_state: State
@export var inside_kick_state: State
@export var head_kick_state: State            # FF + Kick


# ring buffer of recent Inputs [(input, time)]
var _buf: Array[Dictionary] = []  # [{i: StringName, s: float}]

func _process(_dt: float) -> void:
	# Prune old items
	var now: float = Time.get_ticks_msec() * 0.001
	for i in range(_buf.size() - 1, -1, -1):
		if now - float(_buf[i]["s"]) > 1.25:  # keep ~1.25s history
			_buf.remove_at(i)

	# Direction taps -> F/B (camera-relative)
	if Input.is_action_just_pressed("Left") or Input.is_action_just_pressed("Right"):
		var lane_dir: int = _lane_input_to_fb()  # +1 B, -1 F, 0 none/both
		if lane_dir != 0:
			print("F" if lane_dir > 0 else "B")
			_push_input(&"F" if lane_dir > 0 else &"B")

	# Attack
	if Input.is_action_just_pressed("Punch"):
		print("P")
		_push_input(&"P")
		
	if Input.is_action_just_pressed("Kick"):
		print("K")
		_push_input(&"K")
		
func match(sequence:Array[StringName], within_seconds: float) -> bool:
	var now: float = Time.get_ticks_msec() * 0.001
	var idx: int = _buf.size() -1
	var si: int = sequence.size() -1
	
	while si >= 0 and idx >=0:
		var item := _buf[idx]
		var age : float = now - float(item["s"])
		if age > within_seconds:
			break
		if StringName(item["i"]) == sequence[si]:
			si -= 1
		idx -= 1
	return si < 0 
func clear_recent(seconds: float) -> void:
	var now: float = Time.get_ticks_msec() * 0.001
	for i in range(_buf.size() - 1, -1, -1):
		if now - float(_buf[i]["s"]) <= seconds:
			_buf.remove_at(i)
		
func set_camera(cam: Camera3D) -> void:
	_camera_ref = cam
	
func resolve_attack(button: StringName) -> State:
	if match([&"F", &"F", button], ff_window):
		clear_recent(clear_window)
		if button == &"P" and inside_kick_state: return inside_kick_state
		if button == &"K" and head_kick_state: return head_kick_state
	if _is_forward_held():
		if button == &"P" and straight_state: return straight_state
		if button == &"K" and front_kick_state: return front_kick_state
	if _is_back_held():
		if button == &"K" and back_kick_state: return back_kick_state
		
	if button == &"P" and jab_state: return jab_state
	if button == &"K" and neutral_kick_state: return neutral_kick_state
	return null
	
#----------------------Helpers------------------------#
func _push_input(input: StringName) -> void:
	_buf.append({"i": input, "s": Time.get_ticks_msec() * 0.001})

func _lane_axis() -> Vector3:
	if _camera_ref:
		var r := _camera_ref.global_transform.basis.x
		var v := Vector3(r.x,0.0,r.z)
		return v.normalized() if v.length() > 0.0001 else Vector3.RIGHT
	return Vector3.RIGHT
	
func _facing_sign_by_camera() -> float:
	var local_f := (Vector3.RIGHT if visuals_forward_axis == AxisLocal.X else Vector3.FORWARD)
	var world_f := (visuals.global_basis * local_f).normalized()
	return 1.0 if world_f.dot(_lane_axis()) >= 0.0 else -1.0

func _lane_input_to_fb() -> int:
	var left := Input.is_action_pressed("Left")
	var right := Input.is_action_pressed("Right")
	if left == right: return 0
	var facing := _facing_sign_by_camera()
	return 1 if ((right and facing > 0.0) or (left and facing < 0.0)) else -1

func _is_forward_held() -> bool:
	return _lane_input_to_fb() > 0 
func _is_back_held() -> bool:
	return _lane_input_to_fb() < 0
func push_punch() -> void:
	_push_input(&"P")
func push_kick() -> void:
	_push_input(&"K")

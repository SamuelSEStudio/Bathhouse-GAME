extends State
class_name PracticeSidestepState

@export var idle_state: State
@export var forward_state: State
@export var other_sidestep_state: State
@export var backward_state: State
@export var fall_state: State
@export var dodge_state: State
@export var guard_state: State

@export var opponent_body: Node3D
@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
#@export var side_axis: Vector3 = Vector3.RIGHT
@export var depth_sign: float = 1.0

# remembers last side to avoid flicker if both LR are held
var _locked_y: float = 0.0
var _side_sign: float = 0.0 # -1 = left, +1 = right

func _depth_axis_from_current_camera() -> Vector3:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam:
		var fwd: Vector3 = -cam.global_transform.basis.z
		var flat := Vector3(fwd.x, 0.0, fwd.z)
		return flat.normalized() if flat.length() > 0.0001 else Vector3.FORWARD
	return Vector3.FORWARD
	
func _get_lane_dir() -> Vector3:
	# lane_dir = direction from player to opponent, flattened to ground
	if opponent_body == null or player == null:
		# Fallback: use camera depth so the state still works in practice scenes without an enemy
		return _depth_axis_from_current_camera()

	var p_pos: Vector3 = player.global_transform.origin
	var e_pos: Vector3 = opponent_body.global_transform.origin

	var lane: Vector3 = e_pos - p_pos
	lane.y = 0.0

	var length: float = lane.length()
	if length <= 0.001:
		return Vector3.FORWARD

	return lane / length
	
func _get_side_dir(lane_dir: Vector3) -> Vector3:
	# side_dir = axis we use for Tekken-style sidestep
	var side: Vector3 = Vector3.UP.cross(lane_dir)
	var length: float = side.length()
	if length <= 0.001:
		return Vector3.RIGHT
	return side / length


#func _pick_side_from_input() -> void:
	#var fwd: bool = Input.is_action_pressed("Forward")
	#var back: bool = Input.is_action_pressed("Backward")
	#if depth_sign > 0.0 and s:
	#if fwd and !back:
		#_side_sign = 1.0
	#elif back and !fwd:
		#_side_sign = -1.0
	## if both or neither, keep previous _side_sign (prevents jitter)

func enter(payload: Variant = null) -> void:
	super()
	_locked_y = player.visuals.global_rotation.y
	
	#_pick_side_from_input()
	#if _side_sign == 0.0:
		## default to right if nothing was down on enter
		#_side_sign = 1.0

func process_input(event: InputEvent) -> State:
	#var left: bool = Input.is_action_pressed("Left")
	#var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	# No diagonals: if depth pressed, switch to depth states; if no LR, go idle.
	if !(fwd or back): return idle_state
	#if left or right: return idle_state
	if depth_sign > 0.0 and back:
		return other_sidestep_state
	if depth_sign < 0.0 and fwd:
		return other_sidestep_state

	# Still sidestepping -> update side sign
	#_pick_side_from_input()
	return null
	
func process_frame(delta: float) -> State:
	var p: Player = player as Player
	if p != null and p.defence != null:
		var d: DefenceInterpreter = p.defence
		
		if d.just_requested_dodge:
			d.just_requested_dodge = false
			return dodge_state

		if d.wants_guard:
			return guard_state

	return null

func process_physics(delta: float) -> State:
	# 1) Compute Tekken vs-space axes
	var lane_dir: Vector3 = _get_lane_dir()
	var side_dir: Vector3 = _get_side_dir(lane_dir)

	# 2) Movement: circle around opponent along side axis
	var dir: Vector3 = (side_dir * depth_sign).normalized()
	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed

	# 3) Gravity + movement
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	# 4) Keep player facing opponent (Tekken-style)
	if opponent_body != null and player != null:
		var p_pos: Vector3 = player.visuals.global_transform.origin
		var e_pos: Vector3 = opponent_body.global_transform.origin

		# flatten so we only rotate around Y
		var look_target: Vector3 = Vector3(e_pos.x, p_pos.y, e_pos.z)
		player.visuals.look_at(look_target, Vector3.UP)

	# 5) State exit conditions
	if !player.is_on_floor():
		return fall_state

	return null 
	#if lock_visuals_y:
		#player.visuals.global_rotation.y = _locked_y
		#
	#var depth: Vector3 = _depth_axis_from_current_camera()
	#var dir: Vector3 = (depth * depth_sign).normalized()
	##var dir: Vector3 = (depth * _side_sign).normalized()
	##var horiz: Vector3 = Vector3(dir.x, 0.0, dir.z)
#
	#player.velocity.x = dir.x * speed
	#player.velocity.z = dir.z * speed
#
	#player.velocity += player.get_gravity() * delta
	#player.move_and_slide()
#
	#if !player.is_on_floor():
		#return fall_state
	#return null

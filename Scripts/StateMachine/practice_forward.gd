extends State
class_name PracticeForwardState

@export var idle_state: State
@export var backwards_state: State
@export var sidestep_state: State
@export var fall_state: State
@export var guard_state: State
@export var dodge_state: State
@export var combo_ref: ComboInput

@export var neutral_kick_state: State
@export var jab_state: State
 
@export var speed: float = 4.0
@export var lock_visuals_y: bool = true
@export var depth_axis: Vector3 = Vector3.FORWARD #world forward
@export var direction_sign: float = 1.0   # +1 = forward, -1 = backward

@export var opponent_body: Node3D

var _locked_y: float = 0.0

func _get_lane_dir() -> Vector3:
	if player == null:
		return depth_axis.normalized()

	if opponent_body != null:
		var p_pos: Vector3 = player.global_transform.origin
		var e_pos: Vector3 = opponent_body.global_transform.origin
		var lane: Vector3 = e_pos - p_pos
		lane.y = 0.0
		var len: float = lane.length()
		if len > 0.001:
			return lane / len

	# Fallbacks when no opponent (e.g. pure practice mode)

	# 1) Try camera right (so forward/back = across screen)
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam != null:
		var right: Vector3 = cam.global_transform.basis.x
		var flat: Vector3 = Vector3(right.x, 0.0, right.z)
		if flat.length() > 0.0001:
			return flat.normalized()

	# 2) Last resort: fixed world axis from export
	return depth_axis.normalized()
# Called when the node enters the scene tree for the first time.
func enter(payload: Variant = null) -> void:
	super()
	_locked_y = player.visuals.global_rotation.y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func process_input(event: InputEvent) -> State:
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")
	
	if Input.is_action_just_pressed("Kick"):
		if combo_ref:
			combo_ref.push_kick()
			var s := combo_ref.resolve_attack(&"K")
			if s != null:
				return s
		return neutral_kick_state  # fallback if resolver not set

	if Input.is_action_just_pressed("Punch"):
		if combo_ref:
			combo_ref.push_punch()
			var s := combo_ref.resolve_attack(&"P")
			if s != null:
				return s
		return jab_state
	
	if (fwd or back): return sidestep_state
	if left and !right: return backwards_state
	if !right: return idle_state
	return null
	
func process_physics(delta: float) -> State:
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y
	# OPTIONAL: For Tekken boss fights, you might want them to always face the opponent.
	# If so, you can replace the above with the same look_at block used in sidestep,
	# or only do that when opponent_body != null.

	# --- 2. Forward/back along lane (camera right) ---
	var lane_dir: Vector3 = _get_lane_dir()
	var dir: Vector3 = lane_dir * direction_sign
	dir.y = 0.0
	if dir.length() > 0.0001:
		dir = dir.normalized()

	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed

	# --- 3. Gravity + movement ---
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	# --- 4. Exit conditions ---
	if !player.is_on_floor():
		return fall_state

	return null
	##Forward only no diagonal movemnt zero X -> push strictly along depth 
	#var dir: Vector3 = depth_axis.normalized()
	#var horiz: Vector3 = Vector3(dir.x,0.0,dir.z)
	#
	#player.velocity.x = horiz.x * speed
	#player.velocity.z = horiz.z * speed
	#
	#player.velocity+= player.get_gravity() * delta
	#player.move_and_slide()
	#
	#if !player.is_on_floor():
		#return fall_state
	#return null
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

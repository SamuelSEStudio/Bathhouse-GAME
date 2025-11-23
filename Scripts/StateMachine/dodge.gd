extends State
class_name PracticeDodgeState

@export var idle_state: State
@export var forward_state: State
@export var sidestep_state: State
@export var fall_state: State

@export var dodge_duration: float = 0.25
@export var dodge_distance: float = 3.5

@export var invincibility_start: float = 0.05
@export var invincibility_end: float = 0.20

var _time_left: float = 0.0
var _elapsed: float = 0.0
var _horiz_velocity: Vector3 = Vector3.ZERO

var _combatant: Combatant = null

func _depth_axis_from_current_camera() -> Vector3:
	var cam: Camera3D = (player as Player).default_cam
	var forward: Vector3 = -cam.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized()

func _side_axis_from_current_camera() -> Vector3:
	var depth: Vector3 = _depth_axis_from_current_camera()
	# Right-hand perpendicular in XZ plane
	var side: Vector3 = Vector3(depth.z, 0.0, -depth.x)
	return side.normalized()

func enter(payload: Variant = null) -> void:
	super(payload)

	_time_left = dodge_duration
	_elapsed = 0.0

	var input_vec: Vector2 = Input.get_vector("Left", "Right", "Forward", "Backward")
	
	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.has_i_frames = false

	var depth: Vector3 = _depth_axis_from_current_camera()
	var side: Vector3 = _side_axis_from_current_camera()
	var chosen: Vector3

	# Decide dodge direction based on practice-lane inputs
	if input_vec.y > 0.0:
		# Forward dodge
		chosen = depth
	elif input_vec.y < 0.0:
		# Backward dodge
		chosen = -depth
	elif input_vec.x > 0.0:
		# Right dodge (relative to camera)
		chosen = side
	elif input_vec.x < 0.0:
		# Left dodge (relative to camera)
		chosen = -side
	else:
		# Neutral tap → default to backward dodge
		chosen = -depth

	chosen = chosen.normalized()
	var speed: float = dodge_distance / max(dodge_duration, 0.001)

	#_horiz_velocity = chosen * speed
	player.velocity.y = 0.0

	# TODO later: flag invincibility on Combatant here between invincibility_start/end


func exit() -> void:
	super()
	_time_left = 0.0
	_elapsed = 0.0
	_horiz_velocity = Vector3.ZERO
	# TODO: clear invincibility flag if we add one
	if _combatant != null:
		_combatant.has_i_frames = false

func _update_invincibility() -> void:
	if _combatant == null:
		return

	if _elapsed >= invincibility_start and _elapsed <= invincibility_end:
		_combatant.has_i_frames = true
	else:
		_combatant.has_i_frames = false

func process_physics(delta: float) -> State:
	_elapsed += delta
	_time_left -= delta

	player.velocity.x = _horiz_velocity.x
	player.velocity.z = _horiz_velocity.z
	player.velocity += player.get_gravity() * delta

	player.move_and_slide()

	if _time_left <= 0.0:
		if not player.is_on_floor():
			return fall_state

		# After dodge finishes, decide where to go
		var forward_back: bool = (
			Input.is_action_pressed("Forward")
			or Input.is_action_pressed("Backward")
		)
		var left_right: bool = (
			Input.is_action_pressed("Left")
			or Input.is_action_pressed("Right")
		)

		if forward_back and forward_state != null:
			return forward_state
		elif left_right and sidestep_state != null:
			return sidestep_state
		else:
			return idle_state

	return null

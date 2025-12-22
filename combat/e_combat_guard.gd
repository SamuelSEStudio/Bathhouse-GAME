extends State
class_name EnemyGuardState

@export var idle_state: State
@export var forward_state: State
@export var back_state: State
@export var fall_state: State

@export var guard_move_speed: float = 1.5
@export var release_recovery_time: float = 0.05

var _release_timer: float = 0.0
var _releasing: bool = false
var _locked_rotation_y: float = 0.0
var _combatant: Combatant = null


func enter(payload: Variant = null) -> void:
	super(payload)
	_release_timer = 0.0
	_releasing = false

	_locked_rotation_y = player.visuals.global_rotation.y
	player.velocity.x = 0.0
	player.velocity.z = 0.0

	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.is_blocking = true


func exit() -> void:
	super()
	_releasing = false
	_release_timer = 0.0

	if _combatant != null:
		_combatant.is_blocking = false


func process_input(event: InputEvent) -> State:
	return null


func process_frame(delta: float) -> State:
	var thug: ThugMid = player as ThugMid
	if thug == null:
		return null

	# If AI no longer wants to guard, start a small release window,
	# then hand control back to movement/idle.
	if not thug.wants_guard and not _releasing:
		_releasing = true
		_release_timer = release_recovery_time

	if _releasing:
		_release_timer -= delta
		if _release_timer <= 0.0:
			var dir_scalar: float = thug.desired_lane_dir
			if dir_scalar > 0.01 and forward_state != null:
				return forward_state
			if dir_scalar < -0.01 and back_state != null:
				return back_state
			return idle_state

	return null


func process_physics(delta: float) -> State:
	player.visuals.global_rotation.y = _locked_rotation_y

	if not _releasing:
		var thug: ThugMid = player as ThugMid
		if thug != null:
			var lane_dir: Vector3 = thug.lane_axis.normalized()
			var move_dir: Vector3 = Vector3.ZERO

			if thug.desired_lane_dir > 0.01:
				move_dir = lane_dir
			elif thug.desired_lane_dir < -0.01:
				move_dir = -lane_dir

			if move_dir != Vector3.ZERO:
				player.velocity.x = move_dir.x * guard_move_speed
				player.velocity.z = move_dir.z * guard_move_speed
			else:
				player.velocity.x = 0.0
				player.velocity.z = 0.0
	else:
		# During release recovery, no movement
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	return null

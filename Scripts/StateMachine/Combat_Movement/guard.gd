extends State
class_name PracticeGuardState

@export var idle_state: State
@export var forward_state: State
@export var backward_state: State
@export var sidestep_stateI: State
@export var sidestep_stateO: State
@export var dodge_state: State
@export var fall_state: State

@export var depth_axis: Vector3 = Vector3.FORWARD
@export var combo_ref: ComboInput

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
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	var has_lr: bool = left or right
	var has_fb: bool = fwd or back

	var p: Player = player as Player
	if p == null or p.defence == null:
		return null

	var d: DefenceInterpreter = p.defence

	if d.just_requested_dodge and dodge_state != null:
		d.just_requested_dodge = false
		return dodge_state

	if not d.wants_guard and not _releasing:
		_releasing = true
		_release_timer = release_recovery_time

	if _releasing:
		_release_timer -= delta
		if _release_timer <= 0.0:
			if has_fb and (fwd != back):
				return sidestep_stateI if fwd else sidestep_stateO
			if has_lr and (left != right):
				return forward_state if right else backward_state
			return idle_state

	return null


func process_physics(delta: float) -> State:
	player.visuals.global_rotation.y = _locked_rotation_y

	if not _releasing:
		var p: Player = player as Player
		var dir: Vector3 = Vector3.ZERO

		if p != null and combo_ref != null:
			if combo_ref._is_forward_held():
				dir = depth_axis.normalized()
			elif combo_ref._is_back_held():
				dir = -depth_axis.normalized()

		if dir != Vector3.ZERO:
			player.velocity.x = dir.x * guard_move_speed
			player.velocity.z = dir.z * guard_move_speed
		else:
			player.velocity.x = 0.0
			player.velocity.z = 0.0
	else:
		player.velocity.x = 0.0
		player.velocity.z = 0.0

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	return null

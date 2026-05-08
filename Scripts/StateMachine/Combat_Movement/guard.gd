extends State
class_name PracticeGuardState

@export var idle_state: State
@export var forward_state: State
@export var backward_state: State
@export var sidestep_stateI: State
@export var sidestep_stateO: State
@export var dodge_state: State
@export var fall_state: State

@export var release_recovery_time: float = 0.05

var _release_timer: float = 0.0
var _releasing: bool = false
var _locked_rotation_y: float = 0.0


func enter(payload: Variant = null) -> void:
	super(payload)
	_release_timer = 0.0
	_releasing = false

	_locked_rotation_y = player.visuals.global_rotation.y
	player.velocity.x = 0.0
	player.velocity.z = 0.0

	var p: Player = player as Player
	if p != null:
		p.set_combat_blocking(true)


func exit() -> void:
	super()
	_releasing = false
	_release_timer = 0.0

	var p: Player = player as Player
	if p != null:
		p.clear_guard_modifier()


func process_input(event: InputEvent) -> State:
	return null


func _get_movement_state() -> State:
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	var has_lr: bool = left or right
	var has_fb: bool = fwd or back

	if has_fb and (fwd != back):
		return sidestep_stateI if fwd else sidestep_stateO

	if has_lr and (left != right):
		return forward_state if right else backward_state

	return null


func process_frame(delta: float) -> State:
	var p: Player = player as Player
	if p == null or p.defence == null:
		return null

	var d: DefenceInterpreter = p.defence

	if d.just_requested_dodge and dodge_state != null:
		d.just_requested_dodge = false
		return dodge_state

	if d.wants_guard and !_releasing:
		var movement_state: State = _get_movement_state()
		if movement_state != null:
			return movement_state

		p.set_combat_blocking(true)
		return null

	if !d.wants_guard and !_releasing:
		_releasing = true
		_release_timer = release_recovery_time

	if _releasing:
		_release_timer -= delta

		if _release_timer <= 0.0:
			var movement_state_after_release: State = _get_movement_state()
			if movement_state_after_release != null:
				return movement_state_after_release

			return idle_state

	return null


func process_physics(delta: float) -> State:
	player.visuals.global_rotation.y = _locked_rotation_y

	player.velocity.x = 0.0
	player.velocity.z = 0.0

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if !player.is_on_floor():
		return fall_state

	return null

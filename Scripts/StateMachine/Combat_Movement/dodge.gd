extends State
class_name PracticeDodgeState

@export var idle_state: State
@export var forward_state: State
@export var sidestep_state: State
@export var fall_state: State

@export var dodge_duration: float = 0.25

@export var neutral_dodge_anim: StringName = &"dodge_neutral"
@export var forward_dodge_anim: StringName = &"dodge_forward"
@export var back_dodge_anim: StringName = &"dodge_back"
@export var side_in_dodge_anim: StringName = &"dodge_side_in"
@export var side_out_dodge_anim: StringName = &"dodge_side_out"

@export var invincibility_start: float = 0.05
@export var invincibility_end: float = 0.20

var _time_left: float = 0.0
var _elapsed: float = 0.0
var _combatant: Combatant = null


func enter(payload: Variant = null) -> void:
	animation_name = String(_get_dodge_animation())
	super(payload)

	_time_left = dodge_duration
	_elapsed = 0.0

	player.velocity.x = 0.0
	player.velocity.z = 0.0

	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant

	if _combatant != null:
		_combatant.has_i_frames = false


func exit() -> void:
	super()
	_time_left = 0.0
	_elapsed = 0.0

	if _combatant != null:
		_combatant.has_i_frames = false


func _get_dodge_animation() -> StringName:
	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	var has_lr: bool = left or right
	var has_fb: bool = fwd or back

	# Match C_idle movement routing:
	# Forward / Backward inputs are sidestep controls in combat.
	if has_fb and (fwd != back):
		return side_in_dodge_anim if fwd else side_out_dodge_anim

	# Left / Right inputs are forward/back movement controls in combat.
	if has_lr and (left != right):
		return forward_dodge_anim if right else back_dodge_anim

	return neutral_dodge_anim


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

	_update_invincibility()

	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if _time_left <= 0.0:
		if not player.is_on_floor():
			return fall_state

		var forward_back: bool = (
			Input.is_action_pressed("Forward")
			or Input.is_action_pressed("Backward")
		)

		var left_right: bool = (
			Input.is_action_pressed("Left")
			or Input.is_action_pressed("Right")
		)

		if forward_back and sidestep_state != null:
			return sidestep_state
		elif left_right and forward_state != null:
			return forward_state
		else:
			return idle_state

	return null

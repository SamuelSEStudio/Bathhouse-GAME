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
@export var left_dodge_anim: StringName = &"dodge_left"
@export var right_dodge_anim: StringName = &"dodge_right"

@export var invincibility_start: float = 0.05
@export var invincibility_end: float = 0.20

var _time_left: float = 0.0
var _elapsed: float = 0.0
var _combatant: Combatant = null


func enter(payload: Variant = null) -> void:
	super(payload)

	_time_left = dodge_duration
	_elapsed = 0.0

	player.velocity.x = 0.0
	player.velocity.z = 0.0

	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.has_i_frames = false

	_play_dodge_animation()


func exit() -> void:
	super()
	_time_left = 0.0
	_elapsed = 0.0

	if _combatant != null:
		_combatant.has_i_frames = false


func _play_dodge_animation() -> void:
	var anim: StringName = neutral_dodge_anim

	var left: bool = Input.is_action_pressed("Left")
	var right: bool = Input.is_action_pressed("Right")
	var fwd: bool = Input.is_action_pressed("Forward")
	var back: bool = Input.is_action_pressed("Backward")

	if fwd and not back:
		anim = forward_dodge_anim
	elif back and not fwd:
		anim = back_dodge_anim
	elif left and not right:
		anim = left_dodge_anim
	elif right and not left:
		anim = right_dodge_anim

	animation_name = anim


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

		if forward_back and forward_state != null:
			return forward_state
		elif left_right and sidestep_state != null:
			return sidestep_state
		else:
			return idle_state

	return null

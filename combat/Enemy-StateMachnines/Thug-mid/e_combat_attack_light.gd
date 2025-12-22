extends State
class_name EnemyAttackLightState

@export var idle_state: State
@export var fall_state: State

@export var attack_duration: float = 0.5    # seconds the state lasts
@export var lock_visuals_y: bool = true

var _locked_y: float = 0.0
var _timer: float = 0.0


func enter(payload: Variant = null) -> void:
	super(payload)

	_timer = 0.0

	# Optional: lock facing direction for the duration
	if lock_visuals_y:
		_locked_y = player.visuals.global_rotation.y

	# Zero out horizontal velocity so we don't slide around during the jab
	player.velocity.x = 0.0
	player.velocity.z = 0.0

	# NOTE: animation is already handled by base State via animation_name
	# Make sure animation_name on this state is set to your light attack clip.


func process_physics(delta: float) -> State:
	# Maintain locked facing
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	# Simple gravity + slide
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	_timer += delta
	if _timer >= attack_duration:
		# Attack finished, go back to idle
		return idle_state

	return null

extends State
class_name EnemyAttackHeavyState

@export var idle_state: State
@export var fall_state: State

@export var attack_duration: float = 0.8   # longer than light jab
@export var lock_visuals_y: bool = true

var _locked_y: float = 0.0
var _timer: float = 0.0


func enter(payload: Variant = null) -> void:
	super(payload)

	_timer = 0.0

	if lock_visuals_y:
		_locked_y = player.visuals.global_rotation.y

	# Don’t slide around during the heavy
	player.velocity.x = 0.0
	player.velocity.z = 0.0


func process_physics(delta: float) -> State:
	if lock_visuals_y:
		player.visuals.global_rotation.y = _locked_y

	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	_timer += delta
	if _timer >= attack_duration:
		return idle_state

	return null

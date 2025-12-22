extends State
class_name EnemyDodgeState

@export var idle_state: State
@export var fall_state: State

@export var dodge_duration: float = 0.25
@export var dodge_distance: float = 3.5

@export var invincibility_start: float = 0.05
@export var invincibility_end: float = 0.20

var _time_left: float = 0.0
var _elapsed: float = 0.0
var _horiz_velocity: Vector3 = Vector3.ZERO

var _combatant: Combatant = null


func enter(payload: Variant = null) -> void:
	super(payload)

	_time_left = dodge_duration
	_elapsed = 0.0
	_horiz_velocity = Vector3.ZERO

	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.has_i_frames = false

	# Decide dodge direction based on enemy lane axis
	var thug: ThugMid = player as ThugMid
	if thug == null:
		return

	# Use lane_axis from ThugMid as "depth", then compute a side vector
	var depth: Vector3 = thug.lane_axis
	depth.y = 0.0
	if depth.length_squared() == 0.0:
		depth = Vector3.FORWARD
	depth = depth.normalized()

	var side: Vector3 = Vector3(depth.z, 0.0, -depth.x).normalized()

	# Simple AI choice: sidestep left or right at random
	var chosen: Vector3 = side
	if randf() < 0.5:
		chosen = -side

	chosen = chosen.normalized()
	var speed: float = dodge_distance / max(dodge_duration, 0.001)

	#_horiz_velocity = chosen * speed
	player.velocity.y = 0.0


func exit() -> void:
	super()
	_time_left = 0.0
	_elapsed = 0.0
	_horiz_velocity = Vector3.ZERO

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

	_update_invincibility()

	# Apply dodge horizontal velocity
	player.velocity.x = _horiz_velocity.x
	player.velocity.z = _horiz_velocity.z
	player.velocity += player.get_gravity() * delta

	player.move_and_slide()

	if _time_left <= 0.0:
		# End of dodge
		if _combatant != null:
			_combatant.has_i_frames = false

		if not player.is_on_floor():
			return fall_state

		return idle_state

	return null


func process_input(event: InputEvent) -> State:
	# Enemy dodge ignores input
	return null

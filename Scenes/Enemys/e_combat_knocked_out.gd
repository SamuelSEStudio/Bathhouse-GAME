extends State
class_name EnemyKOState

var _combatant: Combatant = null
var _thug: ThugMid = null


func enter(payload: Variant = null) -> void:
	# Plays this state's inspector-assigned animation_name.
	super(payload)

	_thug = player as ThugMid
	_combatant = player.get_node_or_null("Combatant") as Combatant

	# Freeze immediately.
	player.velocity = Vector3.ZERO

	# Clear enemy intent so nothing is queued if this enemy is inspected/debugged later.
	if _thug != null:
		_thug.clear_desired_lane_dir()
		_thug.clear_attack_request()
		_thug.set_guarding(false)


func process_physics(delta: float) -> State:
	# Keep frozen and do not call move_and_slide().
	player.velocity = Vector3.ZERO
	return null


func process_input(event: InputEvent) -> State:
	return null


func process_frame(delta: float) -> State:
	return null

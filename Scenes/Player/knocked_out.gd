extends State
class_name KOState

@export var restart_delay: float = 5.0
@export var combatant_path: NodePath # set to "Combatant" in inspector (relative to the player body)

var _restart_started: bool = false
var _combatant: Combatant = null

func enter(payload: Variant = null) -> void:
	# Plays animation_name via State.enter()
	super(payload)

	# Freeze immediately
	player.velocity = Vector3.ZERO

	# Cache Combatant (so we can tell if this is the player)
	_combatant = player.get_node_or_null(combatant_path) as Combatant

	# Only the player triggers a level restart after a delay
	if _combatant != null and _combatant.if_player:
		_start_restart()

func process_physics(delta: float) -> State:
	# Keep frozen and DO NOT move_and_slide (prevents gravity drift)
	player.velocity = Vector3.ZERO
	return null

func _start_restart() -> void:
	if _restart_started:
		return
	_restart_started = true
	_do_restart.call_deferred()

func _do_restart() -> void:
	# Wait for KO delay
	await get_tree().create_timer(restart_delay).timeout

	# Safety: state/owner may have been freed or scene changed
	if not is_inside_tree():
		return

	# Restart the current scene (Godot 4)
	get_tree().reload_current_scene()

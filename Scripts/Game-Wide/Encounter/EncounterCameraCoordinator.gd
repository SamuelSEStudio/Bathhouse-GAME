extends Node
class_name EncounterCameraCoordinator

# =============================================================================
# Future module
# =============================================================================
# Placeholder for v0.7+.
# Later this should pass group-combat framing information to FightCam2D.
# It should not replace FightCam2D yet.

var _is_running: bool = false
var _debug_enabled: bool = false
var _focus_target: Node3D
var _registered_enemies: Array[Node] = []


func configure_from_profile(
	_profile: EncounterCombatProfile,
	focus_target: Node3D,
	debug_enabled: bool
) -> void:
	_focus_target = focus_target
	_debug_enabled = debug_enabled


func start_coordinating() -> void:
	_is_running = true
	_debug("Started placeholder encounter camera coordinator")


func stop_coordinating() -> void:
	_is_running = false
	_debug("Stopped placeholder encounter camera coordinator")


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	_registered_enemies.clear()

	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant):
			continue

		var enemy_body: Node = combatant.body
		if enemy_body == null:
			continue

		_registered_enemies.append(enemy_body)


func get_relevant_enemies_for_framing() -> Array[Node]:
	# Future behaviour:
	# Return nearby/important enemies for wider camera framing.
	return []


func _debug(message: String) -> void:
	if not _debug_enabled:
		return

	print("EncounterCameraCoordinator: ", message)

extends Node
class_name SoftLockCoordinator

# =============================================================================
# Future module
# =============================================================================
# Placeholder for v0.7+.
# Later this should choose preferred combat targets based on:
# - distance
# - screen/camera angle
# - current enemy role
# - immediate danger
# - current player-facing direction

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
	_debug("Started placeholder soft-lock coordinator")


func stop_coordinating() -> void:
	_is_running = false
	_debug("Stopped placeholder soft-lock coordinator")


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	_registered_enemies.clear()

	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant):
			continue

		var enemy_body: Node = combatant.body
		if enemy_body == null:
			continue

		_registered_enemies.append(enemy_body)


func get_preferred_target() -> Node3D:
	# Future behaviour:
	# Return the best current combat target for the player/camera.
	return null


func _debug(message: String) -> void:
	if not _debug_enabled:
		return

	print("SoftLockCoordinator: ", message)

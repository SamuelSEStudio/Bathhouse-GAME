extends Node
class_name EncounterCameraCoordinator

# =============================================================================
# v0.7a minimal camera bridge
# =============================================================================
# SoftLockCoordinator chooses the preferred opponent.
# This module applies that target to both the player and the existing FightCam2D.
# Wider multi-enemy framing remains a future v0.7b step.

@export var fight_camera: FightCam2D

var _is_running: bool = false
var _debug_enabled: bool = false
var _player_body: Player
var _soft_lock_coordinator: SoftLockCoordinator
var _registered_enemies: Array[Node] = []


func configure_from_profile(
	_profile: EncounterCombatProfile,
	focus_target: Node3D,
	soft_lock_coordinator: SoftLockCoordinator,
	debug_enabled: bool
) -> void:
	_player_body = focus_target as Player
	_soft_lock_coordinator = soft_lock_coordinator
	_debug_enabled = debug_enabled

	if _soft_lock_coordinator != null:
		var callback: Callable = _on_preferred_target_changed
		if not _soft_lock_coordinator.preferred_target_changed.is_connected(callback):
			_soft_lock_coordinator.preferred_target_changed.connect(callback)


func start_coordinating() -> void:
	_is_running = true

	if _soft_lock_coordinator != null:
		_on_preferred_target_changed(_soft_lock_coordinator.get_preferred_target())

	_debug("Started encounter camera bridge")


func stop_coordinating() -> void:
	_is_running = false
	_debug("Stopped encounter camera bridge")


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	_registered_enemies.clear()

	for combatant: Combatant in enemy_combatants:
		if is_instance_valid(combatant) and combatant.body != null:
			_registered_enemies.append(combatant.body)


func get_relevant_enemies_for_framing() -> Array[Node]:
	# v0.7b TODO: include nearby PRESSURE enemies when widening the camera frame.
	return []


func _on_preferred_target_changed(new_target: Node3D) -> void:
	if _player_body != null:
		_player_body.combat_target = new_target

	if fight_camera != null:
		fight_camera.set_opponent(new_target)

	if new_target != null:
		_debug("Applied camera/player target: %s" % new_target.name)


func _debug(message: String) -> void:
	if _debug_enabled:
		print("EncounterCameraCoordinator: ", message)

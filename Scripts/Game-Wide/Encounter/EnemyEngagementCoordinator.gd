extends Node
class_name EnemyEngagementCoordinator

enum EngagementLaneResult {
	CLEAR,
	SCREENED_BY_ALLY,
	TOO_FAR,
	BAD_ANGLE,
	NO_VALID_TARGET,
}

# =============================================================================
# v0.6.2 skeleton
# =============================================================================
# This module is wired now so the attack coordinator has one stable place to ask
# spatial eligibility questions later. v0.6.1 deliberately returns CLEAR so it
# does not change gameplay before the lead-attacker feel pass is validated.

var _is_running: bool = false
var _debug_enabled: bool = false
var _registered_enemies: Array[Node] = []
var _focus_target: Node3D
var _use_lane_checks: bool = false
var _ally_screen_half_angle_degrees: float = 18.0
var _ally_screen_radius: float = 0.85


func configure_from_profile(
	profile: EncounterCombatProfile,
	focus_target: Node3D,
	debug_enabled: bool
) -> void:
	_focus_target = focus_target
	_debug_enabled = debug_enabled

	if profile == null:
		return

	_use_lane_checks = profile.use_engagement_lane_checks
	_ally_screen_half_angle_degrees = profile.ally_screen_half_angle_degrees
	_ally_screen_radius = profile.ally_screen_radius


func start_coordinating() -> void:
	_is_running = true
	_debug("Started engagement-lane placeholder")


func stop_coordinating() -> void:
	_is_running = false
	_debug("Stopped engagement-lane placeholder")


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	_registered_enemies.clear()

	for combatant: Combatant in enemy_combatants:
		if is_instance_valid(combatant) and combatant.body != null:
			_registered_enemies.append(combatant.body)


func get_engagement_lane_result(_enemy: Node) -> EngagementLaneResult:
	# v0.6.2 TODO: check whether an ally is closer to the player and approximately
	# aligned between the requesting enemy and the player.
	return EngagementLaneResult.CLEAR


func has_clear_engagement_lane(enemy: Node) -> bool:
	if not _is_running or not _use_lane_checks:
		return true

	return get_engagement_lane_result(enemy) == EngagementLaneResult.CLEAR


func _debug(message: String) -> void:
	if _debug_enabled:
		print("EnemyEngagementCoordinator: ", message)

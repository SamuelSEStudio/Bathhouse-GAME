extends Node
class_name EnemyAttackCoordinator

signal attack_permission_granted(enemy: Node, role: StringName)
signal attack_permission_denied(enemy: Node, role: StringName)
signal attack_permission_released(enemy: Node)

var max_committed_attackers: int = 1
var default_attack_lock_duration: float = 1.2
var first_attack_delay: float = 0.35
var minimum_gap_between_attacks: float = 0.10
var maximum_gap_between_attacks: float = 0.30

var _role_coordinator: EnemyRoleCoordinator
var _engagement_coordinator: EnemyEngagementCoordinator
var _debug_enabled: bool = false
var _registered_enemies: Array[Node] = []
var _active_attackers: Dictionary = {}
var _is_running: bool = false
var _attack_gap_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not _is_running:
		return

	_attack_gap_timer = maxf(_attack_gap_timer - delta, 0.0)
	_update_active_attackers(delta)


func configure_from_profile(
	profile: EncounterCombatProfile,
	new_role_coordinator: EnemyRoleCoordinator,
	new_engagement_coordinator: EnemyEngagementCoordinator,
	debug_enabled: bool
) -> void:
	_role_coordinator = new_role_coordinator
	_engagement_coordinator = new_engagement_coordinator
	_debug_enabled = debug_enabled

	if profile == null:
		return

	max_committed_attackers = maxi(profile.max_committed_attackers, 1)
	default_attack_lock_duration = profile.default_attack_lock_duration
	first_attack_delay = profile.first_attack_delay
	minimum_gap_between_attacks = profile.minimum_gap_between_attacks
	maximum_gap_between_attacks = profile.maximum_gap_between_attacks


func start_coordinating() -> void:
	_is_running = true
	_active_attackers.clear()
	_attack_gap_timer = first_attack_delay
	_debug("Started coordinating")


func stop_coordinating() -> void:
	_is_running = false
	clear_all_permissions()
	_debug("Stopped coordinating")


func register_enemy(enemy: Node) -> void:
	if enemy == null or _registered_enemies.has(enemy):
		return

	_registered_enemies.append(enemy)
	_debug("Registered enemy: %s" % enemy.name)


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant) or combatant.body == null:
			continue

		var enemy_body: Node = combatant.body
		register_enemy(enemy_body)

		var died_callback: Callable = _on_enemy_died.bind(enemy_body)
		if not combatant.died.is_connected(died_callback):
			combatant.died.connect(died_callback)


func unregister_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	release_attack_permission(enemy, false)
	_registered_enemies.erase(enemy)

	if _role_coordinator != null:
		_role_coordinator.unregister_enemy(enemy)

	_debug("Unregistered enemy: %s" % enemy.name)


func try_request_attack(enemy: Node, role: StringName, lock_duration: float = -1.0) -> bool:
	if enemy == null or not _is_running:
		return _deny(enemy, role, "coordinator is not running")

	if not _registered_enemies.has(enemy):
		register_enemy(enemy)

	if _active_attackers.has(enemy):
		return true

	if _role_coordinator != null and not _role_coordinator.can_request_attack(enemy):
		return _deny(enemy, role, "role cannot currently attack")

	if _engagement_coordinator != null and not _engagement_coordinator.has_clear_engagement_lane(enemy):
		return _deny(enemy, role, "engagement lane is blocked")

	if _attack_gap_timer > 0.0:
		return _deny(enemy, role, "attack gap is active")

	if _active_attackers.size() >= max_committed_attackers:
		return _deny(enemy, role, "committed attacker cap reached")

	var duration: float = default_attack_lock_duration
	if lock_duration > 0.0:
		duration = lock_duration

	_active_attackers[enemy] = duration

	if _role_coordinator != null:
		_role_coordinator.mark_attack_started(enemy)

	_debug("Granted: %s role: %s duration: %.2f" % [enemy.name, role, duration])
	attack_permission_granted.emit(enemy, role)
	return true


func release_attack_permission(enemy: Node, start_recovery: bool = true) -> void:
	if enemy == null or not _active_attackers.has(enemy):
		return

	_active_attackers.erase(enemy)

	if _role_coordinator != null:
		_role_coordinator.mark_attack_released(enemy, start_recovery)

	_start_attack_gap()
	_debug("Released: %s" % enemy.name)
	attack_permission_released.emit(enemy)


func clear_all_permissions() -> void:
	var enemies_to_release: Array[Node] = []

	for key: Variant in _active_attackers.keys():
		var enemy: Node = key as Node
		if enemy != null:
			enemies_to_release.append(enemy)

	_active_attackers.clear()
	_attack_gap_timer = 0.0

	for enemy: Node in enemies_to_release:
		attack_permission_released.emit(enemy)


func has_attack_permission(enemy: Node) -> bool:
	return enemy != null and _active_attackers.has(enemy)


func _update_active_attackers(delta: float) -> void:
	var enemies_to_release: Array[Node] = []
	var invalid_keys: Array[Variant] = []

	for key: Variant in _active_attackers.keys():
		var enemy: Node = key as Node
		if enemy == null or not is_instance_valid(enemy):
			invalid_keys.append(key)
			continue

		var time_left: float = float(_active_attackers[enemy]) - delta
		if time_left <= 0.0:
			enemies_to_release.append(enemy)
		else:
			_active_attackers[enemy] = time_left

	for key: Variant in invalid_keys:
		_active_attackers.erase(key)

	for enemy: Node in enemies_to_release:
		release_attack_permission(enemy)


func _start_attack_gap() -> void:
	var min_gap: float = maxf(minimum_gap_between_attacks, 0.0)
	var max_gap: float = maxf(maximum_gap_between_attacks, min_gap)
	_attack_gap_timer = randf_range(min_gap, max_gap)


func _deny(enemy: Node, role: StringName, reason: String) -> bool:
	if enemy != null:
		_debug("Denied: %s role: %s because %s" % [enemy.name, role, reason])
		attack_permission_denied.emit(enemy, role)

	return false


func _on_enemy_died(enemy: Node) -> void:
	unregister_enemy(enemy)


func _debug(message: String) -> void:
	if _debug_enabled:
		print("EnemyAttackCoordinator: ", message)

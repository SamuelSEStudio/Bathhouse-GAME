extends Node
class_name EnemyRoleCoordinator

enum EnemyRole {
	UNASSIGNED,
	ACTIVE_ATTACKER,      # Current lead attacker. Keeps initiative across attacks.
	PRESSURE,             # Nearby support. Uses its own profile movement.
	HOLD_OFF,             # Extra crowd member. Keeps a wider spacing band.
	RECOVERING,           # Reserved future role. Recovery is timer-based in v0.6.1.
	OPPORTUNITY_ATTACKER, # Temporary support intervention while the lead is pressured.
}

var _registered_enemies: Array[Node] = []
var _enemy_roles: Dictionary = {}
var _attack_recovery_timers: Dictionary = {}

var _is_running: bool = false
var _debug_enabled: bool = false
var _use_roles: bool = true
var _pressure_role_count: int = 1
var _hold_off_role_count: int = 1
var _attack_recovery_duration: float = 0.35
var _lead_initiative_min_duration: float = 2.0
var _lead_initiative_max_duration: float = 4.0
var _rotate_lead_when_timer_expires: bool = true
var _allow_opportunity_interventions: bool = true
var _lead_recently_hit_window: float = 0.85
var _opportunity_intervention_cooldown: float = 1.35
var _hold_off_spacing: Vector2 = Vector2(2.4, 3.5)

var _focus_target: Node3D
var _lead_attacker: Node
var _opportunity_attacker: Node
var _lead_initiative_timer: float = 0.0
var _lead_recently_hit_timer: float = 0.0
var _opportunity_cooldown_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if not _is_running:
		return

	_update_timers(delta)
	_refresh_lead_if_needed()


func configure_from_profile(
	profile: EncounterCombatProfile,
	focus_target: Node3D,
	debug_enabled: bool
) -> void:
	_focus_target = focus_target
	_debug_enabled = debug_enabled

	if profile == null:
		return

	_use_roles = profile.use_roles
	_pressure_role_count = maxi(profile.pressure_role_count, 0)
	_hold_off_role_count = maxi(profile.hold_off_role_count, 0)
	_attack_recovery_duration = maxf(profile.attack_recovery_duration, 0.0)
	_lead_initiative_min_duration = maxf(profile.lead_initiative_min_duration, 0.0)
	_lead_initiative_max_duration = maxf(
		profile.lead_initiative_max_duration,
		_lead_initiative_min_duration
	)
	_rotate_lead_when_timer_expires = profile.rotate_lead_when_timer_expires
	_allow_opportunity_interventions = profile.allow_opportunity_interventions
	_lead_recently_hit_window = maxf(profile.lead_recently_hit_window, 0.0)
	_opportunity_intervention_cooldown = maxf(
		profile.opportunity_intervention_cooldown,
		0.0
	)
	_hold_off_spacing = Vector2(profile.hold_off_min_range, profile.hold_off_max_range)


func start_coordinating() -> void:
	_is_running = true
	_assign_new_lead(null)
	_rebalance_support_roles()
	_debug("Started coordinating")


func stop_coordinating() -> void:
	_is_running = false
	clear_roles()
	_debug("Stopped coordinating")


func register_enemy(enemy: Node) -> void:
	if enemy == null or _registered_enemies.has(enemy):
		return

	_registered_enemies.append(enemy)
	_enemy_roles[enemy] = EnemyRole.UNASSIGNED
	_debug("Registered enemy: %s" % enemy.name)


func register_enemy_combatants(enemy_combatants: Array[Combatant]) -> void:
	for combatant: Combatant in enemy_combatants:
		if not is_instance_valid(combatant):
			continue

		var enemy_body: Node = combatant.body
		if enemy_body == null:
			continue

		register_enemy(enemy_body)

		var got_hit_callback: Callable = _on_enemy_got_hit.bind(enemy_body)
		if not combatant.got_hit.is_connected(got_hit_callback):
			combatant.got_hit.connect(got_hit_callback)


func unregister_enemy(enemy: Node) -> void:
	if enemy == null:
		return

	_registered_enemies.erase(enemy)
	_enemy_roles.erase(enemy)
	_attack_recovery_timers.erase(enemy)

	if enemy == _lead_attacker:
		_lead_attacker = null
		_lead_initiative_timer = 0.0

	if enemy == _opportunity_attacker:
		_opportunity_attacker = null

	_debug("Unregistered enemy: %s" % enemy.name)
	_refresh_lead_if_needed()
	_rebalance_support_roles()


func clear_roles() -> void:
	_enemy_roles.clear()
	_attack_recovery_timers.clear()
	_lead_attacker = null
	_opportunity_attacker = null
	_lead_initiative_timer = 0.0
	_lead_recently_hit_timer = 0.0
	_opportunity_cooldown_timer = 0.0

	for enemy: Node in _registered_enemies:
		if is_instance_valid(enemy):
			_enemy_roles[enemy] = EnemyRole.UNASSIGNED


func set_role(enemy: Node, role: EnemyRole) -> void:
	if enemy == null:
		return

	if not _registered_enemies.has(enemy):
		register_enemy(enemy)

	var previous_role: EnemyRole = get_role(enemy)
	_enemy_roles[enemy] = role

	if previous_role != role:
		_debug("Role set: %s -> %s" % [enemy.name, _role_to_string(role)])


func get_role(enemy: Node) -> EnemyRole:
	if enemy == null or not _enemy_roles.has(enemy):
		return EnemyRole.UNASSIGNED

	return _enemy_roles[enemy] as EnemyRole


func get_role_spacing(role: EnemyRole) -> Vector2:
	match role:
		EnemyRole.HOLD_OFF:
			return _hold_off_spacing

	return Vector2.ZERO


func get_lead_attacker() -> Node:
	return _lead_attacker


func can_request_attack(enemy: Node) -> bool:
	if enemy == null:
		return false

	if _get_living_enemies().size() <= 1:
		return true

	if _attack_recovery_timers.has(enemy):
		return false

	if enemy == _lead_attacker:
		return true

	return _can_request_opportunity_attack(enemy)


func mark_attack_started(enemy: Node) -> void:
	if enemy == null:
		return

	if _lead_attacker == null:
		_assign_new_lead(enemy)

	if enemy == _lead_attacker:
		set_role(enemy, EnemyRole.ACTIVE_ATTACKER)
		return

	if _can_request_opportunity_attack(enemy):
		_opportunity_attacker = enemy
		set_role(enemy, EnemyRole.OPPORTUNITY_ATTACKER)
		_debug("Opportunity intervention started: %s" % enemy.name)


func mark_attack_released(enemy: Node, start_recovery: bool = true) -> void:
	if enemy == null:
		return

	if start_recovery and _attack_recovery_duration > 0.0:
		_attack_recovery_timers[enemy] = _attack_recovery_duration

	if enemy == _opportunity_attacker:
		_opportunity_attacker = null
		_opportunity_cooldown_timer = _opportunity_intervention_cooldown

		if enemy != _lead_attacker:
			set_role(enemy, EnemyRole.PRESSURE)

	# Important: the lead attacker keeps initiative after releasing one attack token.
	if enemy == _lead_attacker:
		set_role(enemy, EnemyRole.ACTIVE_ATTACKER)

	_rebalance_support_roles()


func rebalance_roles() -> void:
	_refresh_lead_if_needed()
	_rebalance_support_roles()


func _update_timers(delta: float) -> void:
	_lead_initiative_timer = maxf(_lead_initiative_timer - delta, 0.0)
	_lead_recently_hit_timer = maxf(_lead_recently_hit_timer - delta, 0.0)
	_opportunity_cooldown_timer = maxf(_opportunity_cooldown_timer - delta, 0.0)

	var finished_recoveries: Array[Node] = []

	for key: Variant in _attack_recovery_timers.keys():
		var enemy: Node = key as Node
		if enemy == null or not is_instance_valid(enemy):
			continue

		var time_left: float = float(_attack_recovery_timers[enemy]) - delta
		if time_left <= 0.0:
			finished_recoveries.append(enemy)
		else:
			_attack_recovery_timers[enemy] = time_left

	for enemy: Node in finished_recoveries:
		_attack_recovery_timers.erase(enemy)


func _refresh_lead_if_needed() -> void:
	var living_enemies: Array[Node] = _get_living_enemies()

	if living_enemies.size() <= 1:
		_lead_attacker = null
		_lead_initiative_timer = 0.0

		for enemy: Node in living_enemies:
			set_role(enemy, EnemyRole.UNASSIGNED)

		return

	if not is_instance_valid(_lead_attacker):
		_assign_new_lead(null)
		_rebalance_support_roles()
		return

	if _lead_initiative_timer > 0.0:
		return

	if not _rotate_lead_when_timer_expires:
		_reset_lead_timer()
		return

	_assign_new_lead(null)
	_rebalance_support_roles()


func _assign_new_lead(preferred_enemy: Node) -> void:
	var candidates: Array[Node] = _get_living_enemies()

	if candidates.size() <= 1:
		_lead_attacker = null
		_lead_initiative_timer = 0.0
		return

	var chosen_enemy: Node = null

	if preferred_enemy != null and candidates.has(preferred_enemy):
		chosen_enemy = preferred_enemy
	else:
		chosen_enemy = _choose_closest_available_enemy(candidates, _lead_attacker)

	if chosen_enemy == null:
		chosen_enemy = _choose_closest_available_enemy(candidates, null)

	_lead_attacker = chosen_enemy
	_reset_lead_timer()

	if _lead_attacker != null:
		set_role(_lead_attacker, EnemyRole.ACTIVE_ATTACKER)
		_debug("Lead attacker: %s" % _lead_attacker.name)


func _choose_closest_available_enemy(candidates: Array[Node], excluded_enemy: Node) -> Node:
	var best_enemy: Node = null
	var best_distance_sq: float = INF

	for enemy: Node in candidates:
		if enemy == excluded_enemy:
			continue

		if _attack_recovery_timers.has(enemy):
			continue

		var enemy_3d: Node3D = enemy as Node3D
		if enemy_3d == null:
			continue

		var distance_sq: float = 0.0
		if _focus_target != null:
			distance_sq = enemy_3d.global_position.distance_squared_to(
				_focus_target.global_position
			)

		if best_enemy == null or distance_sq < best_distance_sq:
			best_enemy = enemy
			best_distance_sq = distance_sq

	return best_enemy


func _rebalance_support_roles() -> void:
	var living_enemies: Array[Node] = _get_living_enemies()

	if not _use_roles or living_enemies.size() <= 1:
		for enemy: Node in living_enemies:
			if enemy != _lead_attacker and enemy != _opportunity_attacker:
				set_role(enemy, EnemyRole.UNASSIGNED)
		return

	var support_enemies: Array[Node] = []

	for enemy: Node in living_enemies:
		if enemy == _lead_attacker or enemy == _opportunity_attacker:
			continue

		support_enemies.append(enemy)

	support_enemies.sort_custom(_sort_by_distance_to_focus)

	for index: int in support_enemies.size():
		var enemy: Node = support_enemies[index]

		if index < _pressure_role_count:
			set_role(enemy, EnemyRole.PRESSURE)
		else:
			set_role(enemy, EnemyRole.HOLD_OFF)


func _can_request_opportunity_attack(enemy: Node) -> bool:
	if not _allow_opportunity_interventions:
		return false

	if enemy == null or enemy == _lead_attacker:
		return false

	if _opportunity_attacker != null:
		return false

	if _opportunity_cooldown_timer > 0.0:
		return false

	if _lead_recently_hit_timer <= 0.0:
		return false

	return get_role(enemy) == EnemyRole.PRESSURE


func _get_living_enemies() -> Array[Node]:
	var living_enemies: Array[Node] = []

	for enemy: Node in _registered_enemies:
		if not is_instance_valid(enemy):
			continue

		var thug: ThugMid = enemy as ThugMid
		if thug != null and is_instance_valid(thug.combatant) and thug.combatant.is_ko:
			continue

		living_enemies.append(enemy)

	return living_enemies


func _sort_by_distance_to_focus(a: Node, b: Node) -> bool:
	if _focus_target == null:
		return false

	var a_node: Node3D = a as Node3D
	var b_node: Node3D = b as Node3D

	if a_node == null or b_node == null:
		return false

	return (
		a_node.global_position.distance_squared_to(_focus_target.global_position)
		< b_node.global_position.distance_squared_to(_focus_target.global_position)
	)


func _reset_lead_timer() -> void:
	_lead_initiative_timer = randf_range(
		_lead_initiative_min_duration,
		_lead_initiative_max_duration
	)


func _on_enemy_got_hit(_damage: int, enemy: Node) -> void:
	if enemy != _lead_attacker:
		return

	_lead_recently_hit_timer = _lead_recently_hit_window
	_debug("Lead attacker was hit: opportunity window opened")


func _role_to_string(role: EnemyRole) -> String:
	match role:
		EnemyRole.UNASSIGNED:
			return "UNASSIGNED"
		EnemyRole.ACTIVE_ATTACKER:
			return "ACTIVE_ATTACKER"
		EnemyRole.PRESSURE:
			return "PRESSURE"
		EnemyRole.HOLD_OFF:
			return "HOLD_OFF"
		EnemyRole.RECOVERING:
			return "RECOVERING"
		EnemyRole.OPPORTUNITY_ATTACKER:
			return "OPPORTUNITY_ATTACKER"

	return "UNKNOWN"


func _debug(message: String) -> void:
	if _debug_enabled:
		print("EnemyRoleCoordinator: ", message)

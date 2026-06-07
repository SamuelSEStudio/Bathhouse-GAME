extends Node
class_name EncounterBase

enum WinCondition {
	NONE,
	DEFEAT_ONE_ENEMY,
	DEFEAT_ALL_ENEMIES
}

enum LossCondition {
	NONE,
	PLAYER_KO
}

enum EncounterOutcome {
	NONE,
	GAME_OVER,
	RETRY_ENCOUNTER,
	RETURN_TO_MAP,
	LOAD_SCENE,
	CONTINUE
}

@export_group("Identity")
@export var encounter_id: StringName = &""
@export var auto_start: bool = true
@export var start_only_once: bool = true

@export_group("Combatants")
@export var player_combatant: Combatant
@export var enemy_combatants: Array[Combatant] = []

@export_group("Encounter Combat Direction")
@export var combat_profile: EncounterCombatProfile
@export var attack_coordinator: EnemyAttackCoordinator
@export var role_coordinator: EnemyRoleCoordinator

@export_group("Win / Loss")
@export var win_condition: WinCondition = WinCondition.NONE
@export var loss_condition: LossCondition = LossCondition.PLAYER_KO

@export var on_win: EncounterOutcome = EncounterOutcome.CONTINUE
@export var on_loss: EncounterOutcome = EncounterOutcome.GAME_OVER

@export_group("Timelines")
@export var play_intro_timeline: bool = false
@export var intro_timeline: StringName = &""

@export var play_win_timeline: bool = false
@export var win_timeline: StringName = &""

@export var play_loss_timeline: bool = false
@export var loss_timeline: StringName = &""

@export_group("Outcome Scenes")
@export_file("*.tscn") var game_over_scene: String = ""
@export_file("*.tscn") var retry_scene: String = ""
@export_file("*.tscn") var return_scene: String = ""
@export_file("*.tscn") var load_scene_on_win: String = ""
@export_file("*.tscn") var load_scene_on_loss: String = ""

@export_group("Timing")
@export var result_delay: float = 1.5

var is_active: bool = false
var has_started: bool = false
var has_finished: bool = false
var defeated_enemies: Array[Combatant] = []


func _ready() -> void:
	_auto_find_coordinators_if_needed()
	_connect_combatants()

	if auto_start:
		start_encounter()


func start_encounter() -> void:
	if start_only_once and has_started:
		return

	has_started = true
	is_active = true
	has_finished = false
	defeated_enemies.clear()

	_start_encounter_combat_direction()

	if play_intro_timeline and intro_timeline != &"":
		await _play_timeline(intro_timeline)


func end_encounter() -> void:
	is_active = false
	has_finished = true

	_stop_encounter_combat_direction()


func _auto_find_coordinators_if_needed() -> void:
	if attack_coordinator == null:
		attack_coordinator = get_node_or_null("EnemyAttackCoordinator") as EnemyAttackCoordinator

	if role_coordinator == null:
		role_coordinator = get_node_or_null("EnemyRoleCoordinator") as EnemyRoleCoordinator


func _start_encounter_combat_direction() -> void:
	if role_coordinator != null:
		role_coordinator.configure(combat_profile)
		role_coordinator.register_enemy_combatants(enemy_combatants)
		role_coordinator.start_coordinating()

	if attack_coordinator != null:
		attack_coordinator.configure(combat_profile, role_coordinator)
		attack_coordinator.register_enemy_combatants(enemy_combatants)
		attack_coordinator.start_coordinating()

	_assign_coordinators_to_enemy_bodies()


func _stop_encounter_combat_direction() -> void:
	if attack_coordinator != null:
		attack_coordinator.stop_coordinating()

	if role_coordinator != null:
		role_coordinator.stop_coordinating()


func _assign_coordinators_to_enemy_bodies() -> void:
	for enemy: Combatant in enemy_combatants:
		if not is_instance_valid(enemy):
			continue

		var enemy_body: ThugMid = enemy.body as ThugMid
		if enemy_body == null:
			continue

		enemy_body.attack_coordinator = attack_coordinator
		enemy_body.role_coordinator = role_coordinator


func _connect_combatants() -> void:
	if is_instance_valid(player_combatant):
		if not player_combatant.died.is_connected(_on_player_died):
			player_combatant.died.connect(_on_player_died)

	for enemy: Combatant in enemy_combatants:
		if not is_instance_valid(enemy):
			continue

		if not enemy.died.is_connected(_on_enemy_died.bind(enemy)):
			enemy.died.connect(_on_enemy_died.bind(enemy))


func _on_player_died() -> void:
	if not is_active or has_finished:
		return

	if loss_condition == LossCondition.PLAYER_KO:
		await _resolve_loss()


func _on_enemy_died(enemy: Combatant) -> void:
	if not is_active or has_finished:
		return

	if not defeated_enemies.has(enemy):
		defeated_enemies.append(enemy)

	if _has_met_win_condition():
		await _resolve_win()


func _has_met_win_condition() -> bool:
	match win_condition:
		WinCondition.NONE:
			return false

		WinCondition.DEFEAT_ONE_ENEMY:
			return defeated_enemies.size() >= 1

		WinCondition.DEFEAT_ALL_ENEMIES:
			return defeated_enemies.size() >= enemy_combatants.size()

	return false


func _resolve_win() -> void:
	end_encounter()

	await _wait_result_delay()

	if play_win_timeline and win_timeline != &"":
		await _play_timeline(win_timeline)

	_apply_outcome(on_win, true)


func _resolve_loss() -> void:
	end_encounter()

	await _wait_result_delay()

	if play_loss_timeline and loss_timeline != &"":
		await _play_timeline(loss_timeline)

	_apply_outcome(on_loss, false)


func _wait_result_delay() -> void:
	if result_delay <= 0.0:
		return

	await get_tree().create_timer(result_delay).timeout


func _play_timeline(timeline: StringName) -> void:
	if timeline == &"":
		return

	Dialogic.start(timeline)
	await Dialogic.timeline_ended


func _apply_outcome(outcome: EncounterOutcome, was_win: bool) -> void:
	match outcome:
		EncounterOutcome.NONE:
			return

		EncounterOutcome.CONTINUE:
			print("You HAVE WON!!")
			return

		EncounterOutcome.GAME_OVER:
			_load_scene(game_over_scene)

		EncounterOutcome.RETRY_ENCOUNTER:
			_load_scene(retry_scene)

		EncounterOutcome.RETURN_TO_MAP:
			_load_scene(return_scene)

		EncounterOutcome.LOAD_SCENE:
			if was_win:
				_load_scene(load_scene_on_win)
			else:
				_load_scene(load_scene_on_loss)


func _load_scene(scene_path: String) -> void:
	if scene_path == "":
		push_warning("EncounterBase: No scene path set for outcome.")
		return

	get_tree().change_scene_to_file(scene_path)

extends CharacterBody3D
class_name ThugMid

enum ControlMode {
	PLAYER,
	DUMMY_IDLE,
	DUMMY_BLOCK_ALL,
	DUMMY_BLOCK_SECOND_HIT,
	AI_PROFILE_1,
	AI_PROFILE_2,
	AI_PROFILE_3,
}

enum MovementMode {
	LANE,
	ARENA,
}

@export_group("Control")
@export var control_mode: ControlMode = ControlMode.AI_PROFILE_2
@export var movement_mode: MovementMode = MovementMode.LANE
@export var combat_target: Node3D
@export var invert_facing: bool = true
@export var lane_axis: Vector3 = Vector3.FORWARD

var encounter_combat_director: EncounterCombatDirector

var desired_lane_dir: float = 0.0
var pending_attack_role: StringName = &""
var wants_guard: bool = false

@onready var visuals: Node3D = $Visuals
@onready var animation_player: AnimationPlayer = $"Visuals/mixamo_base/AnimationPlayer"
@onready var state_machine: Node = $controllers/state_machine
@onready var combatant: Combatant = $Combatant
@onready var ai_brain: Node = $AIBrain


func _ready() -> void:
	add_to_group("enemy_attackers")
	state_machine.init(self)


func _physics_process(delta: float) -> void:
	state_machine.process_physics(delta)


func _process(delta: float) -> void:
	state_machine.process_frame(delta)


func bind_encounter_combat_director(new_director: EncounterCombatDirector) -> void:
	encounter_combat_director = new_director


func clear_encounter_combat_director() -> void:
	encounter_combat_director = null


func set_desired_lane_dir(dir: float) -> void:
	desired_lane_dir = clampf(dir, -1.0, 1.0)


func clear_desired_lane_dir() -> void:
	desired_lane_dir = 0.0


func update_facing_to_combat_target() -> void:
	if combat_target == null or visuals == null:
		return

	var my_pos: Vector3 = visuals.global_transform.origin
	var t_pos: Vector3 = combat_target.global_transform.origin
	var look_target: Vector3 = Vector3(t_pos.x, my_pos.y, t_pos.z)

	visuals.look_at(look_target, Vector3.UP)

	if invert_facing:
		visuals.rotate_y(PI)


func request_attack_permission(role: StringName, lock_duration: float = -1.0) -> bool:
	if encounter_combat_director == null:
		return true

	return encounter_combat_director.request_attack_permission(self, role, lock_duration)


func release_attack_permission(mark_recovering: bool = true) -> void:
	if encounter_combat_director == null:
		return

	encounter_combat_director.release_attack_permission(self, mark_recovering)


func has_attack_permission() -> bool:
	if encounter_combat_director == null:
		return true

	return encounter_combat_director.has_attack_permission(self)


func get_enemy_role() -> EnemyRoleCoordinator.EnemyRole:
	if encounter_combat_director == null:
		return EnemyRoleCoordinator.EnemyRole.UNASSIGNED

	return encounter_combat_director.get_enemy_role(self)


func get_role_spacing(role: EnemyRoleCoordinator.EnemyRole) -> Vector2:
	if encounter_combat_director == null:
		return Vector2.ZERO

	return encounter_combat_director.get_role_spacing(role)


func request_attack(role: StringName) -> void:
	pending_attack_role = role


func clear_attack_request() -> void:
	pending_attack_role = &""


func set_guarding(on: bool) -> void:
	wants_guard = on

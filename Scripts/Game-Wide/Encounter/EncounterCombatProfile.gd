extends Resource
class_name EncounterCombatProfile

# =============================================================================
# Encounter-level combat pacing
# =============================================================================
# This resource controls the whole fight's group-combat pressure rules.
# It is different from ThugAIProfile, which controls one enemy's personality.

@export_group("Committed Attacks")
@export var max_committed_attackers: int = 1
@export var first_attack_delay: float = 0.75
@export var minimum_gap_between_attack_turns: float = 0.65
@export var maximum_gap_between_attack_turns: float = 1.1
@export var default_attack_lock_duration: float = 1.2

@export_group("Recovery")
@export var recovering_duration: float = 1.0
@export var rotate_attackers: bool = true

@export_group("Roles")
@export var use_roles: bool = true
@export var pressure_role_count: int = 1
@export var hold_off_role_count: int = 1

@export_group("Pressure Role Spacing")
@export var pressure_min_range: float = 1.6
@export var pressure_max_range: float = 2.7

@export_group("Hold-Off Role Spacing")
@export var hold_off_min_range: float = 3.0
@export var hold_off_max_range: float = 4.5

@export_group("Future Secondary Pressure")
@export var max_secondary_threats: int = 0
@export var allow_secondary_overlap: bool = false

@export_group("Future Soft Lock")
@export var use_soft_lock_coordinator: bool = false
@export var prefer_active_attacker_as_target: bool = true

@export_group("Future Encounter Camera")
@export var use_encounter_camera_coordinator: bool = false
@export var frame_pressure_enemies: bool = true
@export var frame_hold_off_enemies: bool = false

@export_group("Debug")
@export var debug_encounter_combat: bool = false

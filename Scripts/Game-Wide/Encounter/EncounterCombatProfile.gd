extends Resource
class_name EncounterCombatProfile

# =============================================================================
# Encounter-level group-combat tuning
# =============================================================================
# Individual enemy personality still belongs in ThugAIProfile resources.
# This resource only shapes how a group shares pressure and targeting.

@export_group("Committed Attacks")
@export var max_committed_attackers: int = 1
@export var first_attack_delay: float = 0.35
@export var minimum_gap_between_attacks: float = 0.10
@export var maximum_gap_between_attacks: float = 0.30
@export var default_attack_lock_duration: float = 1.2

@export_group("Lead Attacker")
@export var lead_initiative_min_duration: float = 2.0
@export var lead_initiative_max_duration: float = 4.0
@export var rotate_lead_when_timer_expires: bool = true
@export var attack_recovery_duration: float = 0.35

@export_group("Opportunity Interventions")
@export var allow_opportunity_interventions: bool = true
@export var lead_recently_hit_window: float = 0.85
@export var opportunity_intervention_cooldown: float = 1.35

@export_group("Roles")
@export var use_roles: bool = true
@export var pressure_role_count: int = 1
@export var hold_off_role_count: int = 1

@export_group("Hold-Off Role Spacing")
@export var hold_off_min_range: float = 2.4
@export var hold_off_max_range: float = 3.5

@export_group("Future Pressure Spacing")
# Reserved for later refinement if normal profile movement is not enough.
# v0.6.1 deliberately lets PRESSURE enemies use their own ThugAIProfile logic.
@export var pressure_min_range: float = 1.6
@export var pressure_max_range: float = 2.7
@export var role_spacing_hysteresis: float = 0.20

@export_group("Soft Lock")
@export var use_soft_lock_coordinator: bool = true
@export var soft_lock_rescore_interval: float = 0.12
@export var soft_lock_minimum_hold_duration: float = 0.50
@export var soft_lock_switch_margin: float = 0.75
@export var soft_lock_current_target_bias: float = 1.25
@export var soft_lock_lead_attacker_bias: float = 0.75
@export var soft_lock_opportunity_attacker_bias: float = 2.0

@export_group("Future Engagement Lane")
# Skeleton values for v0.6.2. The coordinator is wired now but does not block lanes yet.
@export var use_engagement_lane_checks: bool = false
@export var ally_screen_half_angle_degrees: float = 18.0
@export var ally_screen_radius: float = 0.85

@export_group("Future Secondary Pressure")
@export var max_secondary_threats: int = 0
@export var allow_secondary_overlap: bool = false

@export_group("Future Encounter Camera")
@export var use_encounter_camera_coordinator: bool = true
@export var frame_pressure_enemies: bool = true
@export var frame_hold_off_enemies: bool = false

@export_group("Debug")
@export var debug_encounter_combat: bool = false

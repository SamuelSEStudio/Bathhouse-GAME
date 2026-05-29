extends Resource
class_name ThugAIProfile


# =============================================================================
# Distance Bands
# =============================================================================

@export_group("Distance Bands")
@export var too_close_range: float = 0.9
@export var true_light_attack_range: float = 1.2
@export var close_pressure_range: float = 1.6
@export var hover_range_min: float = 1.7
@export var hover_range_max: float = 2.7
@export var far_range: float = 4.2
@export var approaching_heavy_min_range: float = 1.8
@export var approaching_heavy_max_range: float = 4.2


# =============================================================================
# Behaviour Toggles
# =============================================================================

@export_group("Behaviour Toggles")
@export var can_use_light_attack: bool = true
@export var can_use_heavy_attack: bool = true
@export var can_backstep: bool = true
@export var can_guard: bool = true
@export var can_dodge: bool = false
@export var can_use_pressure_strings: bool = true


# =============================================================================
# Chance Tuning
# =============================================================================

@export_group("Chance Tuning")
@export_range(0.0, 1.0, 0.01) var retreat_chance_too_close: float = 0.15
@export_range(0.0, 1.0, 0.01) var backstep_chance_too_close: float = 0.25
@export_range(0.0, 1.0, 0.01) var hover_hold_chance: float = 0.45
@export_range(0.0, 1.0, 0.01) var hover_creep_chance: float = 0.55
@export_range(0.0, 1.0, 0.01) var close_creep_chance: float = 0.8
@export_range(0.0, 1.0, 0.01) var approaching_heavy_chance: float = 0.35
@export_range(0.0, 1.0, 0.01) var backstep_chance_after_light: float = 0.18
@export_range(0.0, 1.0, 0.01) var backstep_chance_after_heavy: float = 0.35
@export_range(0.0, 1.0, 0.01) var guard_chance_close: float = 0.10
@export_range(0.0, 1.0, 0.01) var dodge_chance_close: float = 0.0


# =============================================================================
# Cooldowns / Timing
# =============================================================================

@export_group("Cooldowns / Timing")
@export var shared_action_cooldown: float = 0.55
@export var light_attack_cooldown: float = 0.9
@export var heavy_attack_cooldown: float = 2.2
@export var heavy_consider_interval: float = 0.45
@export var dodge_cooldown: float = 2.5

@export var backstep_cooldown: float = 1.6
@export var backstep_duration: float = 0.45
@export var post_light_backstep_delay: float = 0.55
@export var post_heavy_backstep_delay: float = 0.9

@export var guard_min_duration: float = 0.35
@export var guard_max_duration: float = 0.75


# =============================================================================
# Pressure Strings
# =============================================================================

@export_group("Pressure Strings")
@export_range(0.0, 1.0, 0.01) var pressure_string_chance_close: float = 0.22

@export_range(0.0, 10.0, 0.01) var double_light_weight: float = 0.75
@export_range(0.0, 10.0, 0.01) var light_heavy_weight: float = 0.25

@export var pressure_string_cooldown: float = 2.2
@export var pressure_string_step_delay: float = 0.55
@export var pressure_string_cancel_range: float = 2.2

@export_range(0.0, 1.0, 0.01) var backstep_chance_after_string: float = 0.25
@export var post_string_backstep_delay: float = 0.65

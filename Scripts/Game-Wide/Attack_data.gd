class_name AttackData
extends Resource

@export var name: StringName = &""
@export var damage: int = 10
@export var hitstun_frames: int = 18
@export var hitstop_frames: int = 6
@export var knockback: Vector3 = Vector3(0, 2.0, -3.5)
@export var can_multi_hit: bool = false
@export var max_hits_per_target: int = 1
@export var owner_team: int = 0

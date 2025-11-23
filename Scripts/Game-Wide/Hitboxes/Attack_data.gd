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

#----react typing-----
@export_enum("High", "Mid", "Low", "Sweep") var hit_level: int = 1 #default mid
@export_enum("Light","Medium","Heavy","Launcher") var hit_strength: int = 0
#Which authored reaction this move wants
# e.g. &"HURT_LIGHT_FRONT", &"HURT_LIGHT_SIDE", &"HURT_HEAVY"
@export var reaction_id: StringName = &""  # empty = use default hit reaction

# Scale knockback when blocked (1.0 = same as on hit)
@export var block_knockback_scale: float = 1.0
#----hit effects-----
@export var vfx_scene: PackedScene
@export var sfx: AudioStream
@export var camera_shake_mag: float = 0.06
@export var camera_shake_dur: float = 0.08
@export var hitstop_sec: float = 0.06
@export var hitstop_scale: float = 0.05

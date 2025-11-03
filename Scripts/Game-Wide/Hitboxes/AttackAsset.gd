extends Resource
class_name AttackAsset

@export var move: StringName = &""              # e.g., &"Jab"
@export var data: AttackData                    # gameplay (damage, hitstun, etc.)

# attach + geometry (scale-proof; HitBox converts to local)
@export var bone_names: PackedStringArray = []  # e.g., ["mixamorig_LeftHand"]
@export var node_name: StringName = &"HitBox"   # e.g., "HitBox_L"
@export var target_world_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var target_world_offset: Vector3 = Vector3(0.0, 0.1, 0.0)

@export var show_debug_mesh: bool = false

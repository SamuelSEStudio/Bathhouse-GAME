extends Node
class_name HitboxRuntimeApplier

@export var skel: Skeleton3D
@export var profile: HitMoveProfile

func apply_move(move: StringName) -> void:
	if skel == null or profile == null:
		return
	var specs: Array = profile.get_specs(move)
	for spec in specs:
		var mhs: MoveHitSpec = spec
		var bone_name: StringName = _find_first_bone(skel, mhs.bone_names)
		if String(bone_name) == "":
			continue
		var ba: BoneAttachment3D = skel.get_node_or_null("BA_HIT_%s" % [bone_name]) as BoneAttachment3D
		if ba == null:
			continue
		var hb_node: Area3D = ba.get_node_or_null(String(mhs.node_name)) as Area3D
		if hb_node == null:
			continue
		var hb := hb_node as HitBox
		if hb != null:
			hb.target_world_size    = mhs.target_world_size
			hb.target_world_offset  = mhs.target_world_offset
			hb.enforce_world_space  = true
			hb.show_debug_mesh      = mhs.show_debug_mesh
			if mhs.attack_data != null:
				hb.data = mhs.attack_data
			# Re-apply local sizing from world targets
			hb.call_deferred("_apply_world_targets")

func _find_first_bone(s: Skeleton3D, names: PackedStringArray) -> StringName:
	for n in names:
		if s.find_bone(n) != -1:
			return StringName(n)
	return StringName()

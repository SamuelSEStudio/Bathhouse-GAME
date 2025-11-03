@tool
extends Resource
class_name HitProfile

@export var attacks: Array[AttackAsset] = []

func find_by_move(move: StringName) -> AttackAsset:
	for a in attacks:
		if a.move == move:
			return a
	return null

func all_for_build() -> Array[AttackAsset]:
	return attacks

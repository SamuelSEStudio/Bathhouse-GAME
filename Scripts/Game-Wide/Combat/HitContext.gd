extends Resource
class_name HitContext

# Runtime-only payload; no exports needed (not authored in editor)
var attacker: Node3D
var attack: AttackData
var damage: int = 0
var knockback_local_from_attacker: Vector3 = Vector3.ZERO   # authoring convention
var hitstun_frames: int = 0
var world_contact: Vector3 = Vector3.ZERO

# Derived flags (set by Combatant.receive_hit)
var was_counterhit: bool = false
var defender_was_airborne: bool = false
var from_back: bool = false

extends Node
class_name OpponentBrain

@export var target_path: NodePath                   # set to the Player (CharacterBody3D or Node3D)
@export var combatant_path: NodePath                # opponent's Combatant
@export var anim_player_path: NodePath              # opponent's AnimationPlayer playing the jab
@export var hitbox_path: NodePath                   # BA_Hand/HitBox (optional safety check)

@export var attack_anim: StringName = &"jab"
@export var attack_range: float = 1.9               # meters (tune to model scale)
@export var attack_cooldown_sec: float = 0.7
@export var turn_speed_deg: float = 540.0           # deg/s to face target

var _target: Node3D
var _comb: Combatant
var _anim: AnimationPlayer
var _hb: HitBox
var _cooldown: float = 0.0
var _attacking: bool = false

func _ready() -> void:
	_target = get_node_or_null(target_path) as Node3D
	_comb   = get_node_or_null(combatant_path) as Combatant
	_anim   = get_node_or_null(anim_player_path) as AnimationPlayer
	_hb     = get_node_or_null(hitbox_path) as HitBox

	if _anim != null:
		# Optional: listen for anim end to clear _attacking if your clip has no auto-reset
		_anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	if _comb == null:
		return

	# tick cooldown
	if _cooldown > 0.0:
		_cooldown -= delta

	# if stunned, don't act
	if _comb.hitstun_frames > 0:
		_attacking = false
		return

	# must have a target
	if _target == null:
		return

	# face the target smoothly
	_face_target(delta)

	# already mid-attack → let animation/HitBox handle contacts
	if _attacking:
		return

	# check range and cooldown
	var dist: float = _xz_distance_to_target()
	if dist <= attack_range and _cooldown <= 0.0:
		_start_jab()

func _xz_distance_to_target() -> float:
	if _target == null:
		return INF
	var a: Vector3 = (get_parent() as Node3D).global_transform.origin
	var b: Vector3 = _target.global_transform.origin
	var d: Vector3 = Vector3(b.x - a.x, 0.0, b.z - a.z)
	return d.length()

func _face_target(delta: float) -> void:
	var me := (get_parent() as Node3D)
	if me == null or _target == null:
		return
	var from: Vector3 = me.global_transform.basis.z
	var to:   Vector3 = (_target.global_transform.origin - me.global_transform.origin)
	to.y = 0.0
	if to.length() < 0.0001:
		return
	to = to.normalized()
	# Rotate towards -to because in Godot basis.z points "forward" (positive z forward);
	# if your rig uses -Z forward (as you said), we align so me looks towards target.
	var target_fwd: Vector3 = -to
	var angle: float = acos(clamp(from.normalized().dot(target_fwd), -1.0, 1.0))
	var max_step: float = deg_to_rad(turn_speed_deg) * delta
	var t: float = 0.0 if angle <= 0.0001 else min(1.0, max_step / angle)
	var new_fwd: Vector3 = (from.slerp(target_fwd, t)).normalized()
	var basis := me.global_transform.basis
	# reconstruct basis keeping up as Y
	basis.z = new_fwd
	basis.x = basis.z.cross(Vector3.UP).normalized()
	basis.y = basis.x.cross(basis.z).normalized()
	me.global_transform.basis = basis.orthonormalized()

func _start_jab() -> void:
	_attacking = true
	_cooldown = attack_cooldown_sec
	if _anim != null and attack_anim != StringName():
		_anim.play(attack_anim, 0.05)
	# Safety: ensure HitBox exists and has data (debug)
	if _hb != null and _hb.data == null:
		push_warning("[OpponentBrain] HitBox has no AttackData assigned.")

func _on_anim_finished(name: StringName) -> void:
	if name == attack_anim:
		_attacking = false

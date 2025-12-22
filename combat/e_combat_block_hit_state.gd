extends State
class_name EBlockHitState

@export var idle_state: State
@export var guard_state: State
@export var fall_state: State

@export var block_stun_scale: float = 0.7
@export var min_block_stun_sec: float = 0.1
@export var total_time: float = 0.0  # 0 = no upper cap

@export var default_block_anim: StringName
@export var heavy_block_anim: StringName

var _t: float = 0.0
var _stun_time: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _combatant: Combatant = null

func _play_block_animation(hit_strength: int) -> void:
	# AttackData.hit_strength enum: 0=Light, 1=Medium, 2=Heavy, 3=Launcher
	var anim: StringName = default_block_anim

	if hit_strength >= 2 and heavy_block_anim != StringName():
		anim = heavy_block_anim

	animation_name = anim


func enter(payload: Variant = null) -> void:
	_t = 0.0
	_knockback_velocity = Vector3.ZERO

	var attack: AttackData = null
	var attacker_node: Node3D = null

	# Read attack + attacker from payload (HitContext or Dictionary)
	if payload is HitContext:
		var ctx: HitContext = payload as HitContext
		attack = ctx.attack
		attacker_node = ctx.attacker
	elif typeof(payload) == TYPE_DICTIONARY:
		var dict: Dictionary = payload as Dictionary
		if dict.has("attack"):
			attack = dict["attack"] as AttackData
		if dict.has("attacker"):
			attacker_node = dict["attacker"] as Node3D

	if attack != null:
		# --- BLOCKSTUN ---
		var fps: int = Engine.get_physics_ticks_per_second()
		var base_stun: float = float(attack.hitstun_frames) / float(fps)
		var scaled_stun: float = base_stun * block_stun_scale

		_stun_time = max(scaled_stun, min_block_stun_sec)
		if total_time > 0.0:
			_stun_time = min(_stun_time, total_time)

		# --- ANIMATION ---
		_play_block_animation(attack.hit_strength)

		# --- KNOCKBACK ---
		# Start from attack.knockback in attacker's local space, scaled for block
		var kb_local: Vector3 = attack.knockback * attack.block_knockback_scale
		var world_kb: Vector3 = kb_local

		if attacker_node != null:
			world_kb = attacker_node.global_transform.basis * kb_local

		var stun: float = max(_stun_time, 0.001)
		_knockback_velocity = world_kb / stun
	else:
		# Fallback if no payload: fixed short block flinch
		_stun_time = total_time
		_play_block_animation(0)
		_knockback_velocity = Vector3.ZERO
	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.is_blocking = true
	super(payload)


func exit() -> void:
	super()

	if _combatant == null:
		_combatant = player.get_node_or_null("Combatant") as Combatant
	if _combatant != null:
		_combatant.is_blocking = false
		

func process_physics(delta: float) -> State:
	_t += delta

	# Apply constant knockback over the stun window
	player.velocity.x = _knockback_velocity.x
	player.velocity.z = _knockback_velocity.z

	# Gravity + slide
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if not player.is_on_floor():
		return fall_state

	# End of blockstun
	if _t >= _stun_time:
		# Simple AI hook: if this is a ThugMid and it still wants to guard,
		# go back to its Guard state; otherwise idle.
		var thug: ThugMid = player as ThugMid
		if thug != null and guard_state != null and thug.wants_guard:
			return guard_state

		return idle_state

	return null

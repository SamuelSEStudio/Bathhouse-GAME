extends State
class_name EHitReactState


@export var idle_state: State
@export var total_time: float = 0.20  # Fallback if no AttackData/payload
@export var freeze_motion_xz: bool = true

# Anim names wired in the inspector
@export var default_anim: StringName = &"hit_generic"
@export var light_front_anim: StringName = &"hit_light_front"
@export var light_side_anim: StringName = &"hit_light_side"
@export var heavy_anim: StringName = &"hit_heavy"

@export var knockback_damping: float = 8.0  # How quickly knockback velocity eases to 0

var _t: float = 0.0
var _stun_time: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _current_reaction: StringName = &""


func enter(payload: Variant = null) -> void:
	_t = 0.0
	_current_reaction = &""
	_knockback_velocity = Vector3.ZERO
	_stun_time = total_time

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
		# --- HITSTUN ---
		var fps: int = Engine.get_physics_ticks_per_second()
		_stun_time = float(attack.hitstun_frames) / float(fps)

		# --- ANIMATION CHOICE ---
		_current_reaction = attack.reaction_id
		print(attack.name)
		_play_reaction_animation(_current_reaction)

		# --- KNOCKBACK ---
		# Treat attack.knockback as local to the attacker (e.g. forward in their basis)
		var world_kb: Vector3 = attack.knockback
		if attacker_node != null:
			world_kb = attacker_node.global_transform.basis * attack.knockback

		var stun: float = max(_stun_time, 0.001)
		_knockback_velocity = world_kb / stun
	else:
		# No payload / no attack -> fallback
		_stun_time = total_time
		_play_reaction_animation(&"")

	super(payload)


func process_physics(delta: float) -> State:
	# Apply knockback while reacting
	if freeze_motion_xz:
		# Lock any player-driven XZ, but still apply hit knockback
		player.velocity.x = _knockback_velocity.x
		player.velocity.z = _knockback_velocity.z
	else:
		# Add knockback on top of existing motion
		player.velocity.x += _knockback_velocity.x
		player.velocity.z += _knockback_velocity.z

	# Ease knockback velocity toward zero
	_knockback_velocity = _knockback_velocity.move_toward(
		Vector3.ZERO,
		knockback_damping * delta
	)

	# Gravity + slide
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	_t += delta
	if _t >= _stun_time:
		return idle_state

	return null


func process_input(event: InputEvent) -> State:
	# Ignore input while reacting
	return null


func _play_reaction_animation(reaction_id: StringName) -> void:
	var anim: StringName = default_anim

	match reaction_id:
		&"HURT_LIGHT_FRONT":
			anim = light_front_anim
		&"HURT_LIGHT_SIDE":
			anim = light_side_anim
		&"HURT_HEAVY":
			anim = heavy_anim
		_:
			anim = default_anim
	print(anim)
	animation_name = anim

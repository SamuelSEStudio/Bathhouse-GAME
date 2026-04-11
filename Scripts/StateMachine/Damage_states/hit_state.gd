extends State
class_name HitReactState

@export var idle_state: State
@export var total_time: float = 0.20  #fallback if no payload provided
#@export var combatant: Combatant      # set to this character's Combatant
#@export var fallback_state: State           # e.g., your Idle or Move state
#@export var blend_time: float = 0.05
@export var freeze_motion_xz: bool = true

# Optional: exported anim names so you can wire them in the inspector
@export var default_anim: StringName = &"hit_generic"
@export var light_front_anim: StringName = &"hit_light_front"
@export var light_side_anim: StringName = &"hit_light_side"
@export var heavy_anim: StringName = &"hit_heavy"

@export var knockback_damping: float = 8.0  # how quickly knockback velocity eases to 0

#var _combatant: Combatant
var _machine: Node                          # parent state machine (no type coupling)
var _t: float = 0.0 
var _stun_time: float = 0.0
var _knockback_velocity: Vector3 = Vector3.ZERO
var _current_reaction: StringName = &"" 

func enter(payload: Variant = null) -> void:
	_t = 0.0
	_current_reaction = &""

	var attack: AttackData = null
	var attacker_node: Node3D = null
	
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
		_play_reaction_animation(_current_reaction)
		# --- KNOCKBACK ---
		# We treat attack.knockback as local to the attacker (e.g. backwards in their facing).
		var world_kb: Vector3 = attack.knockback

		if attacker_node != null:
			world_kb = attacker_node.global_transform.basis * attack.knockback

		# Travel roughly this displacement over the stun duration
		var stun: float = max(_stun_time, 0.001)
		_knockback_velocity = world_kb / stun
	else:
		# No payload / no attack -> fallback
		_stun_time = total_time
		_play_reaction_animation(&"")
	super(payload)
	
func process_physics(delta: float) -> State:
	#TODO: make knockback a toggle.
	# Apply knockback while reacting
	if freeze_motion_xz:
		# Lock player-driven XZ, but still allow hit knockback
		player.velocity.x = _knockback_velocity.x
		player.velocity.z = _knockback_velocity.z
	else:
		# Add knockback on top of any existing motion (if you ever want that)
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
	#
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
	# Assuming your base State has an 'animation_name' property
	animation_name = anim
#func _ready() -> void:
	## cache machine & combatant
	#_machine = get_parent()
#
	## subscribe to stun signals once
	#if _combatant != null:
		#if not _combatant.entered_hitstun.is_connected(_on_entered_hitstun):
			#_combatant.entered_hitstun.connect(_on_entered_hitstun)
		#if not _combatant.left_hitstun.is_connected(_on_left_hitstun):
			#_combatant.left_hitstun.connect(_on_left_hitstun)
#
#func _on_entered_hitstun(frames: int) -> void:
	## Tell the parent machine to switch into THIS state
	#if _machine != null and "change_state" in _machine:
		#_machine.change_state(self)
#
#func _on_left_hitstun() -> void:
	## If we're still the active state, ask the machine to go back
	#if _machine != null and "change_state" in _machine and fallback_state != null:
		#_machine.change_state(fallback_state)
#
## ---- normal State API ----
#
func process_input(event: InputEvent) -> State:
	#ignore player inputs while reacting
	return null

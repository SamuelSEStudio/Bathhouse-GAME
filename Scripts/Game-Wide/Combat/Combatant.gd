extends Node3D
class_name Combatant

@export var max_health: int = 100
@export var team_id: int = 0 
@export var if_player: bool = true # enemy has no state machine

@export var body_path: NodePath
var body: CharacterBody3D

@export var state_machine: Node
@export var hit_react_state: State
@export var block_hit_react: State
@export var ko_state: State
#var state_machine: Node

var health: int 
var hitstun_frames: int = 0
var is_blocking: bool = false
var has_i_frames: bool = false
var is_ko: bool = false
var movement_locked: bool = false
var combat_locked: bool = false

signal health_changed(current: int, max : int)
signal got_hit(damage: int)
signal died()
#signal entered_hitstun(frames: int)
#signal left_hitstun()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#state_machine = get_node_or_null(state_machine_path)
	body = get_node_or_null(body_path) as CharacterBody3D
	health = max_health
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_ko and body != null:
		body.velocity = Vector3.ZERO
		
	if hitstun_frames > 0:
		hitstun_frames -= 1
		if hitstun_frames == 0:
			emit_signal("left_hitstun")
			
func receive_hit_ctx(ctx: HitContext) -> void:
	# Expecting ctx.attack with damage/hitstun, plus attacker, etc.
	if ctx == null or ctx.attack == null:
		return

	# Ignore hits during invincibility (e.g. dodge)
	if has_i_frames:
		print("Ignoring hit due to i-frames")
		return

	# --- Base damage from AttackData ---
	var dmg: int = int(ctx.attack.damage)

	# --- Block scaling ---
	var blocking: bool = is_blocking
	print(blocking)
	if blocking:
		dmg = roundi(float(dmg) * 0.2)

	# Clamp and apply
	health = maxi(0, health - dmg)

	# Signals are still useful for UI / SFX / debugging
	emit_signal("health_changed", health, max_health)
	emit_signal("got_hit", dmg)
	print(health)

	# --- KO routing (any character) ---
	if health <= 0 and ko_state != null:
		lock_ko(true, false)
		_change_state_safe(ko_state, ctx)
		emit_signal("died")
		return

	# --- Blocked hit → BlockHitState, if available ---
	if blocking and block_hit_react != null:
		_change_state_safe(block_hit_react, ctx)
		return

	# --- Normal hit react ---
	if hit_react_state != null:
		_change_state_safe(hit_react_state, ctx)
		return

# TODO later: you can route to different hit/guard-hit states here if you want

func _change_state_safe(target: State, payload: Variant) -> void:
	state_machine.change_state(target,payload)
	
func can_move() -> bool:
	return (not is_ko) and (not movement_locked)

func can_fight() -> bool:
	return (not is_ko) and (not combat_locked)

func lock_ko(disable_hit_areas: bool = true, disable_body_collisions: bool = false) -> void:
	if is_ko:
		return

	is_ko = true
	movement_locked = true
	combat_locked = true
	has_i_frames = true # optional, prevents further hits after KO

	if body != null:
		body.velocity = Vector3.ZERO

	if disable_hit_areas:
		_set_area_group_enabled(&"HitBoxes", false)
		_set_area_group_enabled(&"HurtBoxes", false)

	if disable_body_collisions and body != null:
		body.collision_layer = 0
		body.collision_mask = 0

func _set_area_group_enabled(group_name: StringName, enabled: bool) -> void:
	# Only affect this combatant subtree
	var stack: Array[Node] = [self]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n.is_in_group(group_name):
			var a: Area3D = n as Area3D
			if a != null:
				a.monitoring = enabled
				a.monitorable = enabled
		for c: Node in n.get_children():
			stack.push_back(c)
#func _apply_knockback(kb: Vector3)-> void:
	#if body:
		#body.velocity = kb

#func _enter_hitstun(frames: int)-> void:
	#hitstun_frames = max(hitstun_frames, frames)
	#emit_signal("entered_hitstun", hitstun_frames)

class_name Player
extends CharacterBody3D

@onready
var defence: DefenceInterpreter = $DefenseInterpreter
@onready 
var camera_mount: Node3D = $Camera_mount
@onready 
var visuals: Node3D = $Visuals
@onready 
var animation_player: AnimationPlayer = $"Visuals/bluebot-root/AnimationPlayer"
@onready 
var state_machine: Node = $controllers/state_machine
@onready 
var selfie_cma: Camera3D = $Selfie_cma
@onready 
var default_cam: Camera3D = $Camera_mount/Default_cam
@onready
var ray_cast_3d: RayCast3D = $Visuals/RayCast3D
@onready 
var inspector_cam: Camera3D = $Visuals/Head/Inspector_cam
@onready 
var head: Node3D = $Visuals/Head

@export var practice_idle_state: Node
@export var default_idle_state: Node
@export var start_in_practice: bool = false
@export var use_internal_cam: bool = true
@export var combat_target: Node3D

#var SPEED = 3.0
#const JUMP_VELOCITY = 4.5
#
#var walking_speed = 3.0
#var running_speed = 5.0
#var running = false
var in_talk = false
var first_person = false
var can_move = true
var in_fight = false

var camera_angle := Vector2.ZERO #yaw,pitch in DEG

var detection_radius: float = 10.0
var input_threshold: float = 0.1

var attack_move_speed: float = 8.0

var attack_timer

#sensitivity of the mouse movement captured
@export var sense_horizontal = 0.2
@export var sense_vertical = 0.2
@export var max_vertical_angle := 80.0 #clamp up down of camera angle
@export var player_combat_cam: Camera3D
@export var cast_distance: float = 8.0 #how far the sphere can sweep
@export var cast_radius: float = 0.8 #cast sphere radius
@export var select_dot_threshold: float = 0.2 #how aligned with stick dir lower= more forgiving
@export var attack_travel_time: float = 0.20 #seconds for the lunge 
@export var attack_cooldown_time: float = 0.3 #seconds before next attack coroutine analogue
@export var attack_standoff: float = 0.9 #stop this far from target (prevents overlap)

@onready var player_combat: ComboInput = $"Player-combat"
@onready var attack_cooldown: Timer = $"Player-combat/AttackCooldown"
@onready var dir_cast: ShapeCast3D = $"Player-combat/Dir_cast"

var target_enemy: Node3D = null
var is_attacking_enemy: bool = false
var _input_lock_count: int = 0
var _combo_was_processing: bool = true

const ATK_RIGHT := "Right"
const ATK_LEFT := "Left"
const ATK_FWD := "Forward"
const ATK_BACK := "Back"


func _ready():
	#adds player to group for camera access
	add_to_group("player")
	#initilaize state machine, passing a reference of the player to the states,
	#that way they can move and act accordingly
	#dir_cast.target_position=Vector3.FORWARD * cast_distance
	#if !attack_cooldown.is_connected("timeout",_on_attack_cooldown_timeout()):
		#attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	state_machine.init(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_default_cam()
	#stops the player moving when a convo starts and then move again once finished
	Dialogic.timeline_started.connect(func():
		can_move = false
		in_talk = true
		_update_input_locking()
		)
	Dialogic.timeline_ended.connect(func():
		can_move = true
		in_talk = false
		_update_input_locking()
		)
	_apply_default_cam_auto()
	if start_in_practice:
		state_machine.call_deferred("change_state",practice_idle_state)
		if is_instance_valid(player_combat):
			player_combat.set_camera(player_combat_cam)

func _unhandled_input(event: InputEvent) -> void:
	if is_input_locked() or in_talk or !can_move:
		return
	state_machine.process_input(event)
	
func _physics_process(delta: float) -> void:
	if is_input_locked() or !can_move:
		return
	if defence != null:
		defence.update_defence(delta)
	state_machine.process_frame(delta)
	state_machine.process_physics(delta)
	
func _process(delta: float) -> void:
	if in_talk or is_input_locked():
		return
	_process_joystick_look()
	if !can_move:
		return
	state_machine.process_frame(delta)
	
	
func lock_input() -> void:
	var was_locked: bool = is_input_locked()
	_input_lock_count += 1
	if !was_locked:
		# stop any drift the instant the UI opens
		velocity.x = 0.0
		velocity.z = 0.0
	_update_input_locking()

func unlock_input() -> void:
	_input_lock_count = max(_input_lock_count - 1, 0)
	_update_input_locking()

func is_input_locked() -> bool:
	return _input_lock_count > 0

func _update_input_locking() -> void:
	# Disable ComboInput polling while *any* lock is active
	# (this stops Kick/Punch being read while UI is open / Dialogic etc.)
	if is_instance_valid(player_combat):
		var should_process: bool = !is_input_locked() and can_move and !in_talk
		player_combat.set_process(should_process)
		
func set_camera_rotation(yaw_delta: float, pitch_delta: float) ->void:
	#update camera angles
	camera_angle.x -= yaw_delta * sense_horizontal
	camera_angle.y = clamp(
		camera_angle.y - pitch_delta * sense_vertical,
		-max_vertical_angle,max_vertical_angle
	)
	#apply to player and camera mount
	rotation.y = deg_to_rad(camera_angle.x)
	if state_machine.current_state is IdleState:
		pass
		#visuals.rotation.y = (deg_to_rad(-camera_angle.x))
	#visuals.rotation.y = (deg_to_rad(-camera_angle.x))
	if first_person:
		head.rotation.x = deg_to_rad(camera_angle.y)
	camera_mount.rotation.x = deg_to_rad(camera_angle.y)
	
func update_facing_to_combat_target() -> void:
	if combat_target == null or visuals == null:
		return

	var my_pos: Vector3 = visuals.global_transform.origin
	var t_pos: Vector3 = combat_target.global_transform.origin

	# Flatten so we only rotate around Y
	var look_target: Vector3 = Vector3(t_pos.x, my_pos.y, t_pos.z)
	visuals.look_at(look_target, Vector3.UP)
	
func _input(event):
#controls the camera via the mouse input rotate_y controls side to side
#camera mount controls updown movement-unclamped(can 360 spin)
	if !start_in_practice:
		if event.is_action_pressed("inspect") && !in_talk:
			can_move = false
			first_person = true
			inspector_cam.set_current(true)
		elif event.is_action_released("inspect") && !in_talk:
			can_move = true
			first_person = false
			set_default_cam()
			
		if InputEventKey or InputEventJoypadButton:
			if Input.is_action_just_pressed("interact") && !in_talk:
				if ray_cast_3d.is_colliding():
					var collider = ray_cast_3d.get_collider()
					if collider.get_parent().has_method("interact"):
						collider.get_parent().interact()
			else:
				pass
		
	if !start_in_practice:
		if event is InputEventMouseMotion:
			set_camera_rotation(event.relative.x, event.relative.y)

	if !can_move:
		return
		

func _process_joystick_look() -> void:
	var look_x := Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var look_y := Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	
	if look_x != 0 or look_y !=0:
		set_camera_rotation(look_x*10,look_y*10)
#basic animation for Dialogic will be moved to a state soon.
func play_animation(anim_name: String) -> void:
	animation_player.play(anim_name)
func set_selfie_cam():
	selfie_cma.set_current(true)
func set_default_cam() -> void:
	_apply_default_cam_auto()
func _in_fight():
	if in_fight:
		return true
	else:
		return false
func _on_attack_cooldown_timeout() -> void:
	is_attacking_enemy = false
	#_move_blocked = false
func enter_practice() -> void:
	in_fight = true
	# Snap into the practice FSM branch
	state_machine.change_state(practice_idle_state)
	# Optional: zero horizontal velocity
	velocity.x = 0
	velocity.z = 0
	# Optional: notify states they’re in practice (if any need it)
	# emit_signal("entered_practice") or set a flag others read
func exit_practice() -> void:
	in_fight = false
	# Return to exploration branch
	state_machine.change_state(default_idle_state)
	# Clear any practice-only artifacts (e.g., dummy target nodes, lane clamps, buffs)
	#_cleanup_practice_artifacts()
	set_default_cam()
#func _cleanup_practice_artifacts() -> void:
	## If your PracticeMove state spawns a dummy target, make sure it’s cleaned up.
	## Example if you stored a ref on the player (or expose a method on the state).
	#var practice_move := practice_idle_state.get_node_or_null("../PracticeMoveState")
	#if practice_move and practice_move.has_method("cleanup"):
		#practice_move.cleanup()
func _apply_default_cam_auto()-> void:
	if !is_instance_valid(default_cam):
		return
	if use_internal_cam:
		default_cam.make_current()
	else:
		default_cam.current = false
#func update_directional_target()-> void:
	#if is_attacking_enemy:
		#return
	#var stick = Vector2(
		#Input.get_action_strength("Right") - Input.get_action_strength("Left"),
		#Input.get_action_strength("Forward") - Input.get_action_strength("Backward")
	#)
	#if stick.length() < 0.1: # deadzone dont change_target 
		#return
	#var cam_basis:= default_cam.global_transform.basis
	#var cam_f:= (-cam_basis.z).normalized()
	#var cam_r:= (-cam_basis.x).normalized()
	#var world_dir: Vector3 = (cam_f * stick.y + cam_r * stick.x).normalized()
	#
	##dir_cast.global_transform = Transform3D(dir_cast.global_transform.basis,global_position)
	##dir_cast.target_position = world_dir*cast_distance
	##dir_cast.force_shapecast_update()
	#
	#var best: Node3D = null
	#var best_score:= -INF
	#for i in dir_cast.get_collision_count():
		#var col:=dir_cast.get_collider(i)
		#if col and col is Node3D and col.is_in_group("enemy"):
			#var to_enemy: Vector3 = (col.global_position - global_position)
			#var dist :=to_enemy.length()
			#var dir_dot := world_dir.dot(to_enemy/max(dist,0.0001))
			#if dir_dot>select_dot_threshold:
				#var score: float = dir_dot + 0.25 * (1.0/max(dist,0.0001))
				#if score>best_score:
					#best_score = score
					#best = col
	#target_enemy = best
	#print(target_enemy)
			
			
	
	
				#
	#if !animation_player.is_playing():
		#is_locked = false
		#
	#if Input.is_action_just_pressed("kick"):
		#if animation_player.current_animation != "kick":
			#animation_player.play("kick")
			#is_locked = true
	#if Input.is_action_pressed("Run"):
		#SPEED = running_speed
		#running = true
	#else:
		#SPEED = walking_speed
		#running = false
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction  and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("Left", "Right", "Foward", "Backward")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#if!is_locked:
			#if running:
				#if animation_player.current_animation != "running":
					#animation_player.play("running")
			#else: 
				#if animation_player.current_animation != "walking":
					#animation_player.play("walking")
		##rotates the Visual aspect of the 3Dmodel to look in the direction we are moving 
			#visuals.look_at(position + direction)
		#
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#if!is_locked:
			#if animation_player.current_animation != "idle":
				#animation_player.play("idle")
				#
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
	#if !is_locked:
		#move_and_slide()

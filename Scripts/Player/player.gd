class_name Player
extends CharacterBody3D

#######PLUGINS##########
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
@onready 
var player_combat: ComboInput = $"Player-combat"
@onready 
var attack_cooldown: Timer = $"Player-combat/AttackCooldown"
@onready 
var dir_cast: ShapeCast3D = $"Player-combat/Dir_cast"
###############################################

#### Editor variables Plug-ins ###############
@export var practice_idle_state: Node
@export var default_idle_state: Node
@export var start_in_practice: bool = false
@export var use_internal_cam: bool = true
@export var combat_target: Node3D

#--Floats etc---
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

##############################################
##### Variables#################
#--Bools--#
var in_talk = false
var first_person = false
var can_move = true
var in_fight = false
var target_enemy: Node3D = null
var is_attacking_enemy: bool = false
var _combo_was_processing: bool = true

#--camera--
var camera_angle := Vector2.ZERO #yaw,pitch in DEG
#--floats--
var _input_lock_count: int = 0
var detection_radius: float = 10.0
var input_threshold: float = 0.1
var attack_move_speed: float = 8.0
var attack_timer
##############################

########const###########
const ATK_RIGHT := "Right"
const ATK_LEFT := "Left"
const ATK_FWD := "Forward"
const ATK_BACK := "Back"

##################### Player Body #####################

func _ready():
	add_to_group("player") # adds player to griup for camera access
	
	#dir_cast.target_position=Vector3.FORWARD * cast_distance
	#if !attack_cooldown.is_connected("timeout",_on_attack_cooldown_timeout()):
		#attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	state_machine.init(self) #initilaize state machine, passing a reference of the player to the states,
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

##################################################################################
##--INPUT LOCKING--##
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

################################################################
###################Camera conrtrol - 
func set_camera_rotation(yaw_delta: float, pitch_delta: float) ->void:
	#update camera angles
	camera_angle.x -= yaw_delta * sense_horizontal
	camera_angle.y = clamp(
		camera_angle.y - pitch_delta * sense_vertical,
		-max_vertical_angle,max_vertical_angle
	)
	rotation.y = deg_to_rad(camera_angle.x)#apply to player and camera mount
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
	var look_target: Vector3 = Vector3(t_pos.x, my_pos.y, t_pos.z)# Flatten so we only rotate around Y
	visuals.look_at(look_target, Vector3.UP)
## how all inputs are processed 
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
###############################################################################
##################PRACTICE MODE###############################################
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
###################################################################################

func _apply_default_cam_auto()-> void:
	if !is_instance_valid(default_cam):
		return
	if use_internal_cam:
		default_cam.make_current()
	else:
		default_cam.current = false
		

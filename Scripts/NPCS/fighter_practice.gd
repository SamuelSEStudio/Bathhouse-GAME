extends CharacterBody3D

var player = null
var state_machine

@export var player_path: NodePath
@export var enemy_detection: Node = null
@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationLibrary_Godot/AnimationPlayer/AnimationTree

const SPEED = 4.0
const ATTACK_RANGE = 2.5

@export var chaseSpeed: float = 5.0
@export var orbitSpeed: float = 1.0
@export var orbit_radius: float = 4.0
@export var orbit_blend_range: float = 2.0
@export var backoff_speed: float = 3.0

var _character: CharacterBody3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node(player_path)
	_character = self as CharacterBody3D
	add_to_group("enemy")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if player == null:
		return
#position of player and self
	var ppos: Vector3 = player.global_position
	var self_pos: Vector3 = global_position
	var to_player: Vector3 = ppos - global_position
	#old var to_player := (ppos - self_pos).normalized()
	var dist: float = to_player.length()
	
	if dist < 0.001:
		return
	#face the player
	look_at(Vector3(ppos.x,self_pos.y,ppos.z),Vector3.UP)
	#direction of player and perpendicular for circling
	var dir_to_play: Vector3 = to_player.normalized() 
	var orbit_dir := to_player.rotated(Vector3.UP, deg_to_rad(90))  # perpendicular
	
	#distance based switch(chase->orbit)
	#old var dist: float = self_pos.distance_to(ppos)
	
	
	#blends chase vs orbit 
	if dist > orbit_radius:
		#what happens depending on distance
		var t: float = clamp((dist - orbit_radius)/ orbit_blend_range,0.0,1.0)
		var chase_weight = t
		var orbit_weight:= 1.0 - t
		var blended: Vector3 = (dir_to_play * chase_weight * chaseSpeed) + (orbit_dir* orbit_weight * orbitSpeed)
		# old var blended: Vector3 = (to_player * chase_weight * chaseSpeed)\
						   #+(orbit_dir * orbit_weight * orbitSpeed)
		velocity = blended
	else:
		#too close -> back off
		var backoff_dir: Vector3 = -dir_to_play* backoff_speed
		velocity = backoff_dir
	#how fast we circle
	#var horizontal: Vector3 = orbit_dir * orbitSpeed
	#velocity.x = blended.x
	#velocity.z = blended.z
	
	#move_and_slide()

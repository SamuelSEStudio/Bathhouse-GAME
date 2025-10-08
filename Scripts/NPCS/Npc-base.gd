class_name NPCBase
extends Node3D

@export var animation_player_path: NodePath
@export var selfie_cam_path: NodePath
@export var cooldown_timer_path: NodePath
@export var convo_area_path: NodePath
@export var default_anim_name: String
@export var timeline_name: String

var animation_player: AnimationPlayer
var selfie_cam: Camera3D
var cinematic_cooldown_timer: Timer
var convo_area: Area3D

#@onready var extraDialouge:bool = false #to be depricated(if theres a better way)
var can_cinematic:bool = false
##for dialogic
#@export var default_anim_name:String
#@onready var cinematic_cooldown: Timer = $cinematic_cooldown
#@export var convo_name:String 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#adds npc to group for cameras
	add_to_group("npcs")
	animation_player = get_node_or_null(animation_player_path) as AnimationPlayer
	#must link to Animationplayer
	if animation_player:
		if default_anim_name == "":
			default_anim_name = animation_player.current_animation
	#default_anim_name = animation_player.current_animation
	selfie_cam = get_node_or_null(selfie_cam_path) as Camera3D
	cinematic_cooldown_timer = get_node_or_null(cooldown_timer_path) as Timer
	convo_area = get_node_or_null(convo_area_path) as Area3D
	#this sets a timer for how long until the player can re-interact with npc #might not need this
	Dialogic.timeline_started.connect(func(): can_cinematic = false)
	
	Dialogic.timeline_ended.connect(timeline_ended)


# Called every frame. 'delta' is the elapsed time since the previous fr#ame.
func _process(delta: float) -> void:
	pass
func play_animation(anim_name: String) -> void:
	animation_player.play(anim_name)
func set_selfie_cam():
	selfie_cam.set_current(true)
func _on_convo_area_body_entered(body: Node3D) -> void:
	pass
	#if body is Player && !convo1:
		#Dialogic.start_timeline("timelinew")
	##temp way that i wanted to move to next convo 
		#convo1 = true
	#elif body is Player && convo1:
		#Dialogic.start_timeline("Front_Desk")
		
func _on_cinematic_cooldown_timeout() -> void:
	can_cinematic = true
	
func timeline_ended():
	animation_player.play(default_anim_name)
	cinematic_cooldown_timer.start()
	
func interact():
	Dialogic.start_timeline(timeline_name)
##--------------------------Onready Functions##----------------------------##
#func _resolve_animation_player() -> AnimationPlayer:
	#var n: Node = null
	#if animation_player_path != NodePath():
		#n = get_node_or_null(animation_player_path)
	#if n == null and has_node("AnimationLibrary_Godot/AnimationPlayer"):
		#n = $AnimationLibrary_Godot/AnimationPlayer
	#return n as AnimationPlayer
	#
#func _resolve_selfie_cam() -> Camera3D:
	#var n: Node = null
	#if selfie_cam_path != NodePath():
		#n = get_node_or_null(selfie_cam_path)
	#if n == null and has_node("Selfie_cam"):
		#n = $Selfie_cam
	#return n as Camera3D
#
#func _resolve_cooldown_timer() -> Timer:
	#var n: Node = null
	#if cooldown_timer_path != NodePath():
		#n = get_node_or_null(cooldown_timer_path)
	#if n == null and has_node("cinematic_cooldown"):
		#n = $cinematic_cooldown
	#return n as Timer
	#
#func _resolve_Convo_area() -> Area3D:
	#var n: Node = null
	#if convo_area_path != NodePath():
		#n = get_node_or_null(convo_area_path)
	#if n == null and has_node("Convo_area"):
		#n = $Convo_area
	#return n as Area3D

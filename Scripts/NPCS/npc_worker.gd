extends Node3D

@onready var animation_player: AnimationPlayer = $AnimationLibrary_Godot/AnimationPlayer
@onready var selfie_cam: Camera3D = $Selfie_cam
@onready var convo1:bool = false
var can_cinematic:bool = false
#for dialogic
@export var default_anim_name:String
@onready var cinematic_cooldown: Timer = $cinematic_cooldown
@export var convo_name:String 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#adds npc to group for cameras
	add_to_group("npcs")
	default_anim_name = animation_player.current_animation
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
	cinematic_cooldown.start()
	
func interact():
	Dialogic.start_timeline("Front_Desk")

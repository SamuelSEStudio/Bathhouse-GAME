extends Node3D
class_name Combatant

@export var max_health: int = 100
@export var team_id: int = 0 
@export var body_path: NodePath
var body: CharacterBody3D

var health: int
var hitstun_frames: int = 0
var is_blocking: bool = false

signal health_changed(current: int, max : int)
signal got_hit(damage: int)
signal entered_hitstun(frames: int)
signal left_hitstun()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body = get_node_or_null(body_path) as CharacterBody3D
	health = max_health
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if hitstun_frames > 0:
		hitstun_frames -= 1
		if hitstun_frames == 0:
			emit_signal("left_hitstun")

func receive_hit(damage: int, knockback: Vector3, hitstun: int, hitstop: int) -> void:
	var final_damage: int = damage
	var final_hitstun: int  = hitstun
	print("HIT")
	#simple blocking example
	if is_blocking:
		final_damage = int(round(damage * 0.2))
		final_hitstun = int(round(hitstun * 0.7))
	health = max(0, health - final_damage)
	emit_signal("health_changed", health, max_health)
	emit_signal("got_hit", final_damage)
	
	_apply_hitstop(hitstop)
	_apply_knockback(knockback)
	_enter_hitstun(final_hitstun)

func _apply_hitstop(frames:int)-> void:
	pass
	
func _apply_knockback(kb: Vector3)-> void:
	if body:
		body.velocity = kb

func _enter_hitstun(frames: int)-> void:
	hitstun_frames = max(hitstun_frames, frames)
	emit_signal("entered_hitstun", hitstun_frames)

class_name State
extends Node

@export
var animation_name: String
@export
var move_speed: float = 3.0

var gravity: int = ProjectSettings.get_setting("physics/3d/default_gravity")

#reference to parent so that it(Player) can be controlled by the state
var player: CharacterBody3D

#accepts optional payload for HitContext
func enter(payload: Variant = null) -> void:
	player.animation_player.play(animation_name)

func exit()-> void:
	pass
	
func process_input(event: InputEvent) ->State:
	return null

func process_frame(delta: float) -> State:
	return null

func process_physics(delta: float) -> State:
	return null

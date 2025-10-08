extends Node

@export 
var starting_state: State

var current_state: State
#Intialise state machine -> get parent var and set for each child.
#enter default start state.
func init(Player: CharacterBody3D) -> void:
	for child in get_children():
		if child is State:
			child.player = Player
		
	#initialise default state
	change_state(starting_state)
	
#Change to the new state by first calling any exit on the current state.
func change_state(new_state: State)-> void:
	if current_state:
		current_state.exit()
		
	current_state = new_state
	current_state.enter()
	
#Pass through functions for the Player to call.
#handling state changes as needed.
func process_physics(delta: float)-> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)
		
func process_input(event:InputEvent)-> void:
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)
		
func process_frame(delta: float)-> void:
	var new_state = current_state.process_frame(delta)
	if new_state:
		change_state(new_state)
		

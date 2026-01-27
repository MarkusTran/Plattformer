extends Node

class_name CharacterStateMachine

@export var  current_state : State
@export var character : CharacterBody2D 

var states : Array[State]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if(child is State):
			states.append(child)
			child.character = character
			#Set the states up with what they need to function
		else:
			push_warning("Child " + child.name + "Is not a State for CharacterStateMAchine")
			
func _physics_process(delta: float) -> void:
	if(current_state.next_state != null):
		switch_states(current_state.next_state)

func check_if_can_move():
	return current_state.can_move

func switch_states(new_state : State):
	if(current_state != null):
		current_state.on_exit()
		current_state.next_state = null
	current_state = new_state
	
	current_state.on_enter()

func _input(event : InputEvent):
	current_state.state_input(event)

# Adapted from https://github.com/pudgypoultry/godotwildjam7-25/blob/main/Sandboxes/Stella/state_machine.gd
extends Node

@export var initial_state : State
var current_state : State
var states : Dictionary = {}

func _ready():
	# add all states to the states dictionary, states are child nodes of the State Manager node
	for child in get_children():
		if child is State:
			# set up the states dictionary
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_state_transition)

	if initial_state:
		initial_state.Enter(initial_state)
		current_state = initial_state

func _process(delta):
	if current_state:
		current_state.Update(delta)
		
func _physics_process(delta):
	if current_state:
		current_state.Physics_Update(delta)

func on_state_transition(old_state:State, new_state:State):
	print("Transitioning from %s to %s" % [ old_state.name, new_state.name ])

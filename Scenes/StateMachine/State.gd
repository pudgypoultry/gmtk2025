# Adapted from https://github.com/pudgypoultry/godotwildjam7-25/blob/main/Sandboxes/Stella/State.gd
extends Node
# skeleton of this code comes from this tutorial:
# https://www.youtube.com/watch?v=ow_Lum-Agbs&ab_channel=Bitlytic
class_name State

signal Transitioned(old_state:State, new_state:State)

func Enter(old_state:State) -> void:
	# called when the state is entered
	old_state.Exit(self)
	
func Exit(new_state:State) -> void:
	# called when the state is exited
	Transitioned.emit(self, new_state)
	
func Update(_delta) -> void:
	pass

func Physics_Update(_delta) -> void:
	pass

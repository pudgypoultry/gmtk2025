class_name IcoPillerMover
extends Node3D

@export var inactive_distance:float = 10.0
@export var icosphere_layer: Node3D

enum piller_state {IN, OUT, MOVING}

class PillerContatiner:
	var state:piller_state
	var node:Node3D
	func _init(state:piller_state, node:Node3D):
		state = state
		node = node

var pillers:Dictionary[String, PillerContatiner] = {}

func _ready() -> void:
	for child:Node3D in icosphere_layer.get_children():
		pillers[child.name] = PillerContatiner.new(piller_state.IN, child)
		MoveRadially(child)

func MoveRadially(obj:Node3D, origin:Vector3=Vector3.ZERO) -> void:
	# move the input obj along vector from origin point to the object's position
	var direction:Vector3 = obj.position - origin
	if pillers[obj.name].state == piller_state.OUT:
		obj.position = (-direction.normalized() * inactive_distance + obj.position) + origin
		pillers[obj.name].state = piller_state.IN
	elif pillers[obj.name].state == piller_state.IN:
		obj.position = (direction.normalized() * inactive_distance + obj.position) + origin
		pillers[obj.name].state = piller_state.OUT
	

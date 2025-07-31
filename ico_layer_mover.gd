class_name IcoPillarMover
extends Node3D

@export var inactive_distance:float = 10.0
@export var icosphere_layer: Node3D
@export var layer:int

enum pillar_state {IN, OUT, MOVING}

class PillarContatiner:
	var state:pillar_state
	var node:Node3D
	func _init(state:pillar_state, node:Node3D):
		state = state
		node = node

var pillars:Dictionary[String, PillarContatiner] = {}

func _ready() -> void:
	for child:Node3D in icosphere_layer.get_children():
		pillars[child.name] = PillarContatiner.new(pillar_state.IN, child)
		child.get_child(0).set_collision_layer_value(12 + layer, true)
		MoveRadially(child, Vector3.ZERO, false)

func MoveRadially(obj:Node3D, origin:Vector3=Vector3.ZERO, animate:bool=true) -> void:
	# move the input obj along vector from origin point to the object's position
	var direction:Vector3 = obj.position - origin
	if true:
		if pillars[obj.name].state == pillar_state.OUT:
			if animate:
				TweenTools.TweenPosition(obj, obj, 
					obj.position - direction.normalized() * inactive_distance + origin,
					0.5)
			else:
				obj.position = (-direction.normalized() * inactive_distance + obj.position) + origin
			
			pillars[obj.name].state = pillar_state.IN
		
		elif pillars[obj.name].state == pillar_state.IN:
			if animate:
				TweenTools.TweenPosition(obj, obj, 
					obj.position + direction.normalized() * inactive_distance + origin,
					0.5)
			else:
				obj.position = (direction.normalized() * inactive_distance + obj.position) + origin
			
			pillars[obj.name].state = pillar_state.OUT
	

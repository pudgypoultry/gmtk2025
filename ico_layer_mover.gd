class_name IcoPillarMover
extends Node3D

@export var inactive_distance:float = 30.0
@export var icosphere_layer: Node3D
@export var layer:int
@export var animation_length:float = 2
const SOUND_SOURCE = preload("res://Scenes/sound_source.tscn")

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

func SoundAtLocation(location:Vector3) -> void:
	var source = SOUND_SOURCE.instantiate()
	get_parent().add_child(source)
	source.position = location
	source.activate(animation_length)

func MoveRadially(obj:Node3D, origin:Vector3=Vector3.ZERO, animate:bool=true) -> void:
	# move the input obj along vector from origin point to the object's position
	var direction:Vector3 = obj.position - origin
	if true:
		if pillars[obj.name].state == pillar_state.OUT:
			if animate:
				var pos:Vector3 = obj.position - direction.normalized() * inactive_distance + origin
				SoundAtLocation(pos)
				TweenTools.TweenPosition(obj, obj, pos, animation_length)
				pillars[obj.name].state = pillar_state.MOVING
				await get_tree().create_timer(animation_length).timeout
			else:
				obj.position = (-direction.normalized() * inactive_distance + obj.position) + origin
			
			pillars[obj.name].state = pillar_state.IN
		
		elif pillars[obj.name].state == pillar_state.IN:
			if animate:
				var pos:Vector3 = obj.position + direction.normalized() * inactive_distance + origin
				SoundAtLocation(pos)
				TweenTools.TweenPosition(obj, obj, pos, animation_length)
				pillars[obj.name].state = pillar_state.MOVING
				await get_tree().create_timer(animation_length).timeout
			else:
				obj.position = (direction.normalized() * inactive_distance + obj.position) + origin
			pillars[obj.name].state = pillar_state.OUT
	

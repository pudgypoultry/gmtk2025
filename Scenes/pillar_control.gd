extends Node3D


@export var player_node:Node3D
@export var pillar_set_L1:IcoPillarMover
@export var pillar_set_L2:IcoPillarMover
@export var pillar_set_L3:IcoPillarMover
@export var pillar_set_L4:IcoPillarMover


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event) -> void:
	if event.is_action_pressed("Toggle Pillar L1"):
		pillar_set_L1.MoveRadially(FindNearestPillar(pillar_set_L1))
	elif event.is_action_pressed("Toggle Pillar L2"):
		pillar_set_L2.MoveRadially(FindNearestPillar(pillar_set_L2))
	elif event.is_action_pressed("Toggle Pillar L3"):
		pillar_set_L3.MoveRadially(FindNearestPillar(pillar_set_L3))
	elif event.is_action_pressed("Toggle Pillar L4"):
		pillar_set_L4.MoveRadially(FindNearestPillar(pillar_set_L4))
		
func FindNearestPillar(pillar_set) -> Node3D:
	var min_pos:float = 10000000
	var target:Node3D
	for pillar in pillar_set.get_child(0).get_children():
		var dis:float = (pillar.position - player_node.position).length_squared()
		if dis < min_pos:
			min_pos = dis
			target = pillar
	print("found target: " + target.name)
	return target

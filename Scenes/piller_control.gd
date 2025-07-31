extends Node3D


@export var player_node:Node3D
@export var piller_set_L1:IcoPillerMover
@export var piller_set_L2:IcoPillerMover
@export var piller_set_L3:IcoPillerMover
@export var piller_set_L4:IcoPillerMover

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("Toggle Piller L1"):
		piller_set_L1.MoveRadially(FindNearestPiller(piller_set_L1))
	elif Input.is_action_pressed("Toggle Piller L2"):
		piller_set_L2.MoveRadially(FindNearestPiller(piller_set_L2))
	elif Input.is_action_pressed("Toggle Piller L3"):
		piller_set_L3.MoveRadially(FindNearestPiller(piller_set_L3))
	elif Input.is_action_pressed("Toggle Piller L4"):
		piller_set_L4.MoveRadially(FindNearestPiller(piller_set_L4))
		
func FindNearestPiller(piller_set) -> Node3D:
	var min_pos:float = 10000000
	var target:Node3D
	for piller in piller_set.get_child(0).get_children():
		var dis:float = (piller.position - player_node.position).length_squared()
		if dis < min_pos:
			min_pos = dis
			target = piller
	#print("found target: " + target.name)
	return target

extends Node3D

@export var player_node:Node3D
@export var pillar_set_L1:IcoPillarMover
@export var pillar_set_L2:IcoPillarMover
@export var pillar_set_L3:IcoPillarMover
@export var pillar_set_L4:IcoPillarMover
@export var shell_node:Node3D
@export var shell_detection_ray:RayCast3D

func _input(event) -> void:
	if event.is_action_pressed("Toggle Pillar L1"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 1)
		var obj:Node3D = await FindTargetPillarByLayer(shell_detection_ray, 1)
		#var obj:Node3D = FindNearestPillar(pillar_set_L1)
		if obj:
			pillar_set_L1.MoveRadially(obj)
	elif event.is_action_pressed("Toggle Pillar L2"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 2)
		var obj:Node3D = await FindTargetPillarByLayer(shell_detection_ray, 2)
		#var obj:Node3D = FindNearestPillar(pillar_set_L2)
		if obj:
			pillar_set_L2.MoveRadially(obj)
	elif event.is_action_pressed("Toggle Pillar L3"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 3)
		var obj:Node3D = await FindTargetPillarByLayer(shell_detection_ray, 3)
		#var obj:Node3D = FindNearestPillar(pillar_set_L3)
		if obj:
			pillar_set_L3.MoveRadially(obj)
	elif event.is_action_pressed("Toggle Pillar L4"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 4)
		var obj:Node3D = await FindTargetPillarByLayer(shell_detection_ray, 4)
		#var obj:Node3D = FindNearestPillar(pillar_set_L4)
		if obj:
			pillar_set_L4.MoveRadially(obj)
		
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


func FindTargetPillarByLayer(ray:RayCast3D, set_number:int, layer_int:int=12) -> Node3D:
	var shell_normal:Vector3
	# look for the shell in raycast
	if ray.is_colliding():
		var obj = ray.get_collider()
		# check if shell has been found
		#print("Raycast Shell Find: " + obj.get_parent().name)
		if obj.get_parent().name == shell_node.get_child(0).get_child(0).name:
			# get the normal direction on shell
			shell_normal = ray.get_collision_normal()

	# check the physics process directly for the temporary raycast
	var space_state = get_world_3d().direct_space_state
	# check from the origin in the direction of -shell_normal
	var query = PhysicsRayQueryParameters3D.create(Vector3.ZERO, -shell_normal * 100)
	# set layer mask layer to set_number + layer_int
	query.set_collision_mask(pow(2, set_number+layer_int-1))
	#await get_tree().create_timer(10).timeout
	# activate the ray cast
	var result = space_state.intersect_ray(query)
	if result:
		print("Found Pillar: " + result.collider.get_parent().name)
		# return pillar matching set
		return result.collider.get_parent()
	return null

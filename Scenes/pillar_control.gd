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
		var obj:Node3D = FindNearestPillar(pillar_set_L1)
		if obj:
			pillar_set_L1.MoveRadially(obj)
	elif event.is_action_pressed("Toggle Pillar L2"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 2)
		var obj:Node3D = FindNearestPillar(pillar_set_L2)
		if obj:
			pillar_set_L2.MoveRadially(obj)
	elif event.is_action_pressed("Toggle Pillar L3"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 3)
		var obj:Node3D = FindNearestPillar(pillar_set_L3)
		if obj:
			pillar_set_L3.MoveRadially(obj)
	elif event.is_action_pressed("Toggle Pillar L4"):
		#var obj:Node3D = await FindTargetPillar(shell_detection_ray, 4)
		var obj:Node3D = FindNearestPillar(pillar_set_L4)
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
	
# uses input RayCast3D to find the wall of the shell,
# then uses the normal of the wall to find the pillar of the given set number
func FindTargetPillar(ray:RayCast3D, set_number:int) -> Node3D:
	# https://forum.godotengine.org/t/possible-to-detect-multiple-collisions-with-raycast2d/27326
	var shell_normal:Vector3
	# look for the shell in raycast
	var all_collisions = []
	while ray.is_colliding():
		var obj = ray.get_collider()
		# check if shell has been found
		print("Raycast Shell Find: " + obj.get_parent().name)
		if obj.get_parent().name == shell_node.get_child(0).get_child(0).name:
			# get the normal direction on shell
			shell_normal = ray.get_collision_normal()
			break
		# continue with search
		all_collisions.append(obj)
		ray.add_exception(obj)
		ray.force_raycast_update()
	
	# clear exceptions
	for obj in all_collisions:
		ray.remove_exception( obj )
		
	# look for column meshes with a ray from origin in -normal direction
	if shell_normal:
		var excluded_meshes = []
		if set_number == 1:
			excluded_meshes = find_all(pillar_set_L2, StaticBody3D)
			excluded_meshes.append_array(find_all(pillar_set_L3, StaticBody3D))
			excluded_meshes.append_array(find_all(pillar_set_L4, StaticBody3D))
		if set_number == 2:
			excluded_meshes = find_all(pillar_set_L1, StaticBody3D)
			excluded_meshes.append_array(find_all(pillar_set_L3, StaticBody3D))
			excluded_meshes.append_array(find_all(pillar_set_L4, StaticBody3D))
		if set_number == 3:
			excluded_meshes = find_all(pillar_set_L1, StaticBody3D)
			excluded_meshes.append_array(find_all(pillar_set_L2, StaticBody3D))
			excluded_meshes.append_array(find_all(pillar_set_L4, StaticBody3D))
		if set_number == 4:
			excluded_meshes = find_all(pillar_set_L1, StaticBody3D)
			excluded_meshes.append_array(find_all(pillar_set_L2, StaticBody3D))
			excluded_meshes.append_array(find_all(pillar_set_L3, StaticBody3D))
		
		#excluded_meshes.append_array(find_all(player_node, StaticBody3D))
		excluded_meshes.append_array(find_all(shell_node, StaticBody3D))
		
		print("Excluded Meshes: ", excluded_meshes.size())
		# check the physics process directly for the temporary raycast
		var space_state = get_world_3d().direct_space_state
		# check from the origin in the direction of -shell_normal
		var query = PhysicsRayQueryParameters3D.create(Vector3.ZERO, -shell_normal * 100)
		# skip all the meshes we are not looking for
		#await get_tree().create_timer(10).timeout
		query.exclude = excluded_meshes
		# activate the ray cast
		var result = space_state.intersect_ray(query)
		if result:
			print("Found Pillar: " + result.collider.get_parent().name)
			# return pillar matching set
			return result.collider.get_parent()
	return null

# https://www.reddit.com/r/godot/comments/16kkpo2/finding_child_node_by_type/
func find_all(parent, type, node_array:Array[Node]=[]) -> Array[Node]:
	for child in parent.get_children():
		if is_instance_of(child, type):
			node_array.append(child)
		var grandchildern:Array = find_all(child, type)
		if grandchildern.size() > 0:
			node_array.append_array(grandchildern)
	return node_array

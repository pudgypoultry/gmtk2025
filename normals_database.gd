extends Node3D

var normals_database:Dictionary
# Keys are strings
# Values are Vector3
@export var radien_step:float = PI / 30

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var pi_over_2:float = PI / 2
	var phi:float = -PI
	while phi < PI:
		var theta:float = -PI
		while theta < PI:
			# test direction
			TryAddNormal(Vector3(cos(phi) * sin(theta), sin(theta) * sin(phi), cos(theta)))
			# increment theta
			theta += radien_step
		# increment phi
		phi += radien_step
	print("Added %d normal values" % normals_database.size())

func TryAddNormal(ray:Vector3) -> void:
	# check the physics process directly for the temporary raycast
	# set layer mask layer to 12 which is the shell
	# activate the ray cast
	var result = PhysicsProcessRaycast(Vector3.ZERO, ray * 50, pow(2, 12-1))
	if result:
		#print("Normal: ", result.normal)
		# return pillar matching set
		var key:String = NormalToKey(result.normal)
		if normals_database.find_key(key):
			pass
		else:
			normals_database[key] = result.normal
			
func PhysicsProcessRaycast(from:Vector3, to:Vector3, collistion_mask:int) -> Dictionary:
	# check the physics process directly for the temporary raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# set layer mask
	query.set_collision_mask(collistion_mask)
	# activate the ray cast
	return space_state.intersect_ray(query)
	
func NormalToKey(normal:Vector3) -> String:
	return "%.1f|%.1f|%.1f" % [normal.x, normal.y, normal.z]

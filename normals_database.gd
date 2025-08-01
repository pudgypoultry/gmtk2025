extends Node3D

var normals_database:Dictionary
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
	var space_state = get_world_3d().direct_space_state
	# check from the origin in the direction of -shell_normal
	var query = PhysicsRayQueryParameters3D.create(Vector3.ZERO, ray * 50)
	# set layer mask layer to 12 which is the shell
	query.set_collision_mask(pow(2, 12-1))
	# activate the ray cast
	var result = space_state.intersect_ray(query)
	if result:
		#print("Normal: ", result.normal)
		# return pillar matching set
		var key:String = NormalToKey(result.normal)
		if normals_database.find_key(key):
			pass
		else:
			normals_database[key] = result.normal
	
func NormalToKey(normal:Vector3) -> String:
	return "%.1f|%.1f|%.1f" % [normal.x, normal.y, normal.z]

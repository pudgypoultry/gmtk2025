extends Node3D

var normals_database:Dictionary
# Keys are strings - id of tile (normal to 1 decimal place)
# Values are Vector3 - normal of tile
var positions_database:Dictionary
var adjacencies_database:Dictionary
# Keys are strings - id of tile
# Values are Vector3 - position of tile center
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
	# build the position database
	for key in normals_database.keys():
		var result = PhysicsProcessRaycast(Vector3.ZERO, -normals_database[key]*200, pow(2, 12-1))
		if result:
			positions_database[key] = result.position
	print("Added %d position values" % positions_database.size())


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
	return "%.2f|%.2f|%.2f" % [normal.x, normal.y, normal.z]


func FloodArea(key : String, visitedList : Array, numSteps : int, trackingDict : Dictionary = {}):
	# Terminal Step
	print("Starting with: " + key)
	var workingDict = trackingDict
	if numSteps == 0:
		print("	Found endpoint: " + key)
		return {key : 1}
	# Recursive Step
	else:
		for tile in adjacencies_database[key]:
			if tile not in visitedList and tile not in workingDict.keys():
				workingDict[tile] = 1
				print("	Searching through: " + tile)
				var newTiles = FloodArea(tile, visitedList, numSteps - 1, workingDict)
				for adjacentTile in newTiles.keys():
					workingDict[adjacentTile] = 1
	return workingDict

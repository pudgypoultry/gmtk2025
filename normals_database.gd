extends Node3D

var normals_database:Dictionary[String, Vector3]
# Keys are strings - id of tile (normal to 1 decimal place)
# Values are Vector3 - normal of tile
var positions_database:Dictionary[String, Vector3]
var adjacencies_database:Dictionary
var active_database:Dictionary[String, bool]
# Keys are strings - id of tile
# Values are Vector3 - position of tile center
@export var radien_step:float = PI / 30
var full_collision_mask:int = pow(2, 12-1) + pow(2, 13-1) + pow(2, 14-1) + pow(2, 15-1) + pow(2, 16-1)


# Called when the node enters the scene tree for the first time.
func GameSetup() -> void:
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
		active_database[key] = false
	print("Added %d position values" % positions_database.size())
	CreateAdjacencies()
	


func ClearDatabase():
	normals_database.clear()
	positions_database.clear()
	adjacencies_database.clear()
	for key in active_database.keys():
		active_database[key] = false


func TryAddNormal(ray:Vector3) -> void:
	# check the physics process directly for the temporary raycast
	# set layer mask layer to 12 which is the shell
	# activate the ray cast
	var result = PhysicsProcessRaycast(Vector3.ZERO, ray * 50, pow(2, 12-1))
	if result:
		#print("Normal: ", result.normal)
		# return pillar matching set
		var key:String = NormalToKey(result.normal)
		if key in normals_database:
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


func PositionToKey(position:Vector3) -> String:
	for key in positions_database.keys():
		if (position - positions_database[key]).length() < 0.01:
			return key
	return ""


func CreateAdjacencies():
	for i in range(len(positions_database.keys())):
		var currentTile = positions_database[positions_database.keys()[i]]
		var minDistances = [1000, 1001, 1002]
		var minTiles = ["A", "B", "C"]
		for j in range(len(positions_database.keys())):
			if i == j:
				continue
			var currentOther = positions_database[positions_database.keys()[j]]
			if (currentTile - currentOther).length() < minDistances.max():
				var currentIndex = minDistances.find(minDistances.max())
				minDistances[currentIndex] = (currentTile - currentOther).length()
				minTiles[currentIndex] = positions_database.keys()[j]
		adjacencies_database[positions_database.keys()[i]] = minTiles


func FloodArea(key : String, visitedList : Array, numSteps : int, trackingList : Array = []) -> Array:
	# Terminal Step
	# print("Starting with: " + key)
	var workingList = trackingList
	var noAdjacencies = true
	# workingList.append(key)
	if numSteps == 1:
		# print("	Found endpoint: " + key)
		return [key]
	# Recursive Step
	else:
		for tile in adjacencies_database[key]:
			if tile not in visitedList and tile not in trackingList:
				noAdjacencies = false
				workingList.append(tile)
				# print("	Searching through: " + tile)
				var newTiles = FloodArea(tile, visitedList, numSteps - 1, workingList)
				for adjacentTile in newTiles:
					workingList.append(adjacentTile)
	if noAdjacencies:
		return [key]
	var finalList = []
	for item in workingList:
		if item not in finalList:
			finalList.append(item)
	return finalList

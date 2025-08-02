extends CharacterBody3D

@export_category("Game Rules")
@export var rotationSpeed : float = 5.0
@export var verticalCameraClamp : float = 75
@export var speed : float = 5
@export var runSpeed : float = 10
@export var maxTileLineLength : int = 10
@export var tileCheckTolerance : float = 0.05
@export var rotationCheckTolerance : float = 0.05
@export var rotationCheckInterval : float = 0.01
@export var dotDifferenceTolerance : float = 0.02
@export var cooldownAmount : float = 0.5
@export var planeIntersectionTolerance : float = 0.01


@export_category("Plugging in Nodes")
@export var head : Node3D
@export var camera : Node3D
@export var camTarget : Node3D
@export var rayFolder : Node3D
@export var normalCheckray : RayCast3D
@export var tileLightUp : PackedScene
var debugArray = []

var worldReference
var gravity := Vector3(0,-3,0)
var jumpVec := Vector3(0, 75, 0)
var avgNormal : Vector3 = Vector3.UP
var MOUSE_SENS := 0.005
var tileCheckTimer : float = 0.0
var rotationCheckTimer : float = 0.0
var baseSpeed
var extravelocity := Vector3.ZERO
var jumpVectors := Vector3.ZERO
var lastUpDirection : Vector3 = Vector3.UP
var bodyOn : StaticBody3D
var currentTarget : Node3D = null
var mouseSensMulti := 1
var tempDict : Dictionary = {}
var visitedTileNormals : Array = []
var visitedTilePositions : Array = []
var checkingForNewTile : bool = false
var onDifferentTile : bool = true
var isRotating : bool = false
var isOnCooldown : bool = false
var cooldownTimer : float = 0.0
var currentLevel : int = 1
var lastTileNormal : Vector3 = Vector3.UP


func _ready() -> void:
	NormalsDatabase.normals_database.clear()
	NormalsDatabase._ready()
	worldReference = get_parent()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	velocity = Vector3.ZERO
	baseSpeed = speed


func bodyEntered(body) -> void:
	if body and body != bodyOn and body is StaticBody3D:
		bodyOn = body
		jumpVectors = Vector3.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera.rotation.x += -event.relative.y * MOUSE_SENS 
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(verticalCameraClamp), deg_to_rad(verticalCameraClamp))
		# rotation.y += -event.relative.x * MOUSE_SENS * mouseSensMulti
		transform.basis = transform.basis.rotated(up_direction, -event.relative.x * MOUSE_SENS * mouseSensMulti)
	if abs(camera.rotation_degrees.x) >= 360:
		camera.rotation_degrees.x = 0
	if abs(head.rotation_degrees.y) >= 360:
		head.rotation_degrees.y = 0
	if abs(camera.rotation_degrees.x) > 90:
		mouseSensMulti = -1
	else:
		mouseSensMulti = 1


func checkRays() -> void:
	var avgNor := Vector3.ZERO
	var numOfRaysColliding := 0
	var forwardColliding = false
	for ray in rayFolder.get_children():
		var r : RayCast3D = ray
		if r.is_colliding():
			numOfRaysColliding += 1
			avgNor += r.get_collision_normal()

	if avgNor:
		avgNor /= numOfRaysColliding
		avgNormal = avgNor.normalized()
		jumpVec = avgNormal * 50
		gravity = avgNormal * -3
		# print(avgNormal)
	#else: # come back and showcase this
		#avgNormal = Vector3.UP
		#jumpVec = avgNormal * 50
		#gravity = avgNormal * -3

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	if Input.is_action_pressed("Run"):
		speed = runSpeed
	else:
		speed = baseSpeed
	if Input.is_key_pressed(KEY_ESCAPE):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	rotationCheckTimer += delta
	if rotationCheckTimer > rotationCheckInterval:
		rotationCheckTimer = 0
		if up_direction.dot(lastUpDirection) > 1 - rotationCheckTolerance:
			isRotating = false
		else: 
			isRotating = true
		lastUpDirection = up_direction
		# print(isRotating)
	OrientCharacterToDirection(up_direction, delta)
	velocity = speed * get_dir()
	checkRays()
	if not is_on_floor():
		jumpVectors += gravity
#		avgNormal = Vector3.UP
	elif is_on_floor():
		jumpVectors = Vector3.ZERO
	velocity += jumpVectors
	ManageVisitedTileNormals(delta)
	up_direction = avgNormal.normalized()
	move_and_slide()


func NormalToKey(normal):
	return NormalsDatabase.NormalToKey(normal)

func NormalDatabaseKeys():
	return NormalsDatabase.normals_database.keys()


func ManageVisitedTileNormals(delta):
	if isOnCooldown:
		cooldownTimer += delta
		if cooldownTimer > cooldownAmount:
			cooldownTimer = 0
			isOnCooldown = false
	
	# if our up_direction changed, we're potentially on a new tile
	if !isRotating && onDifferentTile && !isOnCooldown:
		checkingForNewTile = true
	
	# if current tile is the same as last we checked and we are in the state of checking to see that we're on a new tile
	if checkingForNewTile and lastUpDirection == up_direction:
		# need to see if we've been on the same up_direction for some amount of time
		tileCheckTimer += delta
		if tileCheckTimer > tileCheckTolerance && !isRotating:
			tileCheckTimer = 0
			var currentNormal = normalCheckray.get_collision_normal()
			var currentKey = NormalToKey(currentNormal)
			if currentKey in NormalDatabaseKeys() && currentNormal != lastTileNormal:
				onDifferentTile = true
	
	if onDifferentTile && !isOnCooldown:
		if normalCheckray.is_colliding():
			SteppedOnNewTile(normalCheckray.get_collision_normal())



func SteppedOnNewTile(tileNormal : Vector3):
	# if up_direction changes AND new up_direction is contained in the tile dictionary,
	#	then I stepped on a new tile for sure
	# First, check that that tile is not in the array already
	#	If it is, initiate check for successful loop
	#	Otherwise, light it up and keep going
	checkingForNewTile = false
	if normalCheckray.is_colliding() :
		var currentNormal = normalCheckray.get_collision_normal()
		var currentKey = NormalToKey(currentNormal)
		if currentKey in NormalDatabaseKeys():
			var newTile = NormalsDatabase.normals_database[currentKey]
			if newTile in visitedTileNormals and newTile != visitedTileNormals[len(visitedTileNormals)-1] and len(visitedTileNormals) > 2:
				CheckForTileLoop(newTile)
			elif newTile not in visitedTileNormals:
				# print("Added " + str(newTile) + " to visited tiles!")
				visitedTileNormals.append(newTile)
				visitedTilePositions.append(NormalsDatabase.positions_database[currentKey])
				var newLightUp = tileLightUp.instantiate()
				get_parent().add_child(newLightUp)
				# TODO: tilePosition = use find nearest pillar to get the middle point of the tile 
				newLightUp.position = NormalsDatabase.positions_database[currentKey]
				newLightUp.basis = basis
				newLightUp.rotate_x(deg_to_rad(90))
				newLightUp.position += newLightUp.basis.y
				debugArray.append(newLightUp)
				#print(visitedTileNormals)
			onDifferentTile = true
			lastTileNormal = newTile


func CheckForTileLoop(repeatedTile):
	isOnCooldown = true
	# Make sure there are at least 3 tiles, otherwise it's just doubling back and you know whatever
	# Get average normal 
	print("Starting tile loop check")
	var loopedTiles = []
	var atLooped = false
	for tile in visitedTileNormals:
		if tile == repeatedTile:
			atLooped = true
		if atLooped:
			loopedTiles.append(tile)
	var average = Vector3.ZERO
	var numNormals = 0
	for norm in loopedTiles:
		numNormals += 1
		average += norm
	if average:
		average /= numNormals
		average = average.normalized()

	# If any tile in the dict *and* that isn't in visitedTileNormals has a closer dot product to the avg normal than
	# any tile in visitedTileNormals, we know it's been looped
	var minDotProductDifference = 1
	for tile in loopedTiles:
		var currentDot = average.dot(tile)
		if 1 - currentDot < minDotProductDifference:
			minDotProductDifference = 1 - currentDot
	print("Minimum diff: " + str(minDotProductDifference))
	ActivateTiles(average, minDotProductDifference)
	visitedTileNormals.clear()
	for i in range(len(debugArray)):
		debugArray.pop_front().queue_free()
		# await get_tree().create_timer(0.2).timeout


func CheckForTilesInLoop():
	var planeArray = []
	var foundTiles = []
	for i in range(len(visitedTilePositions) - 1):
		for j in range(len(visitedTilePositions.slice(i+1)) - 1):
			pass
			# create plane from visitedTilePositions[i] to visitedTilePositions[j]
			var currentPlane = Plane(visitedTilePositions[i], visitedTilePositions[j], visitedTilePositions[i] + Vector3.UP)
			planeArray.append(currentPlane)
	for i in range(len(planeArray) - 1):
		for j in range(len(planeArray.slice(i+1)) - 1):
			pass
			# check if plane[i] and plane[j] intersect at a right angle
			if planeArray[i].dot(planeArray[j]) < planeIntersectionTolerance:
				pass
			# if so, add to the found tiles any tile that the planes both overlap
			#	as long as that tile is not in visitedTiles and isn't already in the list
			#	also potentially check if tile is "near" to the other two tiles to avoid hitting ceiling



func ActivateTiles(average : Vector3, minDotProductDifference : float):
	for tile in NormalsDatabase.normals_database.values():
		var currentDot = average.dot(tile)
		# print("Current diff: " + str(1 - currentDot))
		#if 1 - currentDot < minDotProductDifference and 1 - currentDot <= 1 and tile not in visitedTileNormals and 1 - currentDot < dotDifferenceTolerance:
		if 1 - currentDot < minDotProductDifference and 1 - currentDot <= 1 and tile not in visitedTileNormals:
			ActivateTile(tile)
			await get_tree().create_timer(0.2).timeout


func ActivateTile(tile : Vector3):
	print("Trying to activate: " + str(NormalToKey(tile)) + " : " + str(NormalsDatabase.normals_database[NormalToKey(tile)]))
	worldReference.ActivatePillarByNormal(NormalsDatabase.normals_database[NormalToKey(tile)], currentLevel)


func get_dir() -> Vector3:
	var dir : Vector3 = Vector3.ZERO
	var fowardDir : Vector3 = ( camTarget.global_transform.origin - head.global_transform.origin  ).normalized()
	var dirBase :Vector3= avgNormal.cross( fowardDir ).normalized()
	var inputLeftRight = Input.get_axis("MoveLeft","MoveRight")
	var inputForwardBack = Input.get_axis("MoveBackward","MoveForward")

	var rawInput = Vector2(inputLeftRight, -inputForwardBack)
	var input = Vector3(rawInput.x, 0, rawInput.y)
	
	if Input.is_action_pressed("MoveForward"):
		dir += dirBase.rotated( avgNormal.normalized(), -PI/2 )
	if Input.is_action_pressed("MoveBackward"):
		dir += dirBase.rotated( avgNormal.normalized(), PI/2 )
	if Input.is_action_pressed("MoveLeft"):
		dir += dirBase
	if Input.is_action_pressed("MoveRight"):
		dir += dirBase.rotated(avgNormal.normalized(), PI)
	return dir.normalized()


func OrientCharacterToDirection(direction : Vector3, delta : float):
	if direction.length_squared() > 0:
		var backAxis : Vector3 = basis.z
		var rightAxis := -backAxis.cross(direction)
		
		var rotationBasis := Basis(rightAxis, direction, backAxis).orthonormalized()
		#print("Original Basis:")
		#print(basis)
		basis = basis.get_rotation_quaternion().slerp(rotationBasis, delta * rotationSpeed)

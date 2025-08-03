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
@export var scorePerTile : int = 100
@export var scoreLengthMultiplier : float = 1.1
@export var startingTime : float = 60.0
@export var winPercentage : float = 0.333


@export_category("Plugging in Nodes")
@export var head : Node3D
@export var camera : Node3D
@export var camTarget : Node3D
@export var rayFolder : Node3D
@export var normalCheckray : RayCast3D
@export var tileLightUp : PackedScene
@export var scoreLabel : Label
@export var timeLabel : Label
@export var percentageLabel : Label
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
var playerWins : bool = false
var cooldownTimer : float = 0.0
var currentLevel : int = 1
var lastTileNormal : Vector3 = Vector3.UP
var playerScore : int = 0
var remainingTime
var canAct = true
var currentActive = 0


func _ready() -> void:
	NormalsDatabase.normals_database.clear()
	NormalsDatabase.GameSetup()
	worldReference = get_parent()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	velocity = Vector3.ZERO
	baseSpeed = speed
	remainingTime = startingTime


func bodyEntered(body) -> void:
	if body and body != bodyOn and body is StaticBody3D:
		bodyOn = body
		jumpVectors = Vector3.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera.rotation.x += -event.relative.y * MOUSE_SENS 
		camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(verticalCameraClamp), deg_to_rad(verticalCameraClamp))
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
	
	if Input.is_action_just_pressed("TestWin"):
		InitiateWin()
	remainingTime -= delta
	scoreLabel.text = "SCORE: " + str(playerScore)
	timeLabel.text = "TIME LEFT: %.2f" % [remainingTime]
	percentageLabel.text = "PERCENTAGE COVERED: %.2f" % [float(currentActive) / float(len(NormalsDatabase.active_database.keys()))]


func _physics_process(delta: float) -> void:
	if playerWins: 
		playerWins = false
		await get_tree().create_timer(2).timeout
		InitiateWin()
	
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
				CheckForTilesInLoop(newTile)
				visitedTileNormals.clear()
				visitedTilePositions.clear()
				for i in range(len(debugArray)):
					debugArray.pop_front().queue_free()
			elif newTile not in visitedTileNormals:
				# print("Added " + str(newTile) + " to visited tiles!")
				visitedTileNormals.append(newTile)
				visitedTilePositions.append(NormalsDatabase.positions_database[currentKey])
				var newLightUp = tileLightUp.instantiate()
				get_parent().add_child(newLightUp)
				# TODO: tilePosition = use find nearest pillar to get the middle point of the tile 
				var dir:Vector3 = -NormalsDatabase.normals_database[currentKey] * 100
				newLightUp.position = NormalsDatabase.PhysicsProcessRaycast(Vector3.ZERO, dir, NormalsDatabase.full_collision_mask).position
				var s:float = 1 / currentLevel
				newLightUp.scale = Vector3(s, s, s)
				#newLightUp.rotate_x(deg_to_rad(90))
				newLightUp.basis = Basis(
					-self.basis.z.cross(NormalsDatabase.normals_database[currentKey]),
					NormalsDatabase.normals_database[currentKey], 
					self.basis.z
				).orthonormalized()
				# newLightUp.position += newLightUp.basis.y
				debugArray.append(newLightUp)
				#print(visitedTileNormals)
			onDifferentTile = true
			lastTileNormal = newTile



func CheckForTilesInLoop(repeatedTile):
	isOnCooldown = true
	var checkingArrays = []
	var correctArray = []
	var foundInside = false
	# Make sure there are at least 3 tiles, otherwise it's just doubling back and you know whatever
	# Get average normal 
	# print("Starting tile loop check")
	var loopedTiles = []
	var atLooped = false
	for tile in visitedTileNormals:
		if tile == repeatedTile:
			atLooped = true
		if atLooped:
			loopedTiles.append(tile)
	var i = 0
	for tile in loopedTiles:
		var floodIgnoreList = []
		for loopedTile in loopedTiles:
			floodIgnoreList.append(NormalToKey(loopedTile))
		var currentArray = await NormalsDatabase.FloodArea(NormalToKey(tile), floodIgnoreList, 13)
		currentArray.sort()
		if len(checkingArrays) > 0 and len(currentArray) < 20:
			for array in checkingArrays:
				if currentArray == array:
					foundInside = true
					correctArray = currentArray
					break
		if foundInside:
			break
		checkingArrays.append(currentArray)
	if len(correctArray) > 0:
		for tile in correctArray:
			await get_tree().create_timer(0.05).timeout
			ActivateTile(tile)
		IncreaseScore(len(correctArray))
		CheckForWinState(winPercentage)


func IncreaseScore(numTiles):
	playerScore += ceil((scorePerTile * numTiles) * pow(scoreLengthMultiplier + float(currentLevel)/10, numTiles))


func ResetScore():
	playerScore = 0


func CheckForWinState(percentNeeded):
	var numActive : float = 0
	for key in NormalsDatabase.active_database.keys():
		if NormalsDatabase.active_database[key]:
			numActive += 1
	if numActive / float(len(NormalsDatabase.active_database.keys())) > percentNeeded:
		playerWins = true


func InitiateWin():
	canAct = false
	print("Current Level: " + str(currentLevel))
	match currentLevel:
		1:
			print("FIRST LEVEL COMPLETE")
			var newPosition = NormalsDatabase.positions_database[NormalToKey(-up_direction)]
			position = newPosition
			for key in NormalsDatabase.normals_database.keys():
				if !NormalsDatabase.active_database[key]:
					ActivateTile(key, true)
			await get_tree().create_timer(worldReference.pillar_set_L1.animation_length).timeout
			currentLevel += 1
			NormalsDatabase.ClearDatabase()
			NormalsDatabase.GameSetup()
		2:
			print("SECOND LEVEL COMPLETE")
			for key in NormalsDatabase.normals_database.keys():
				if !NormalsDatabase.active_database[key]:
					ActivateTile(key, true)
			await get_tree().create_timer(worldReference.pillar_set_L2.animation_length).timeout
			currentLevel += 1
			NormalsDatabase.ClearDatabase()
			NormalsDatabase.GameSetup()
		3:
			print("THIRD LEVEL COMPLETE")
			ResetBoard()
			await get_tree().create_timer(worldReference.pillar_set_L1.animation_length + worldReference.pillar_set_L2.animation_length + worldReference.pillar_set_L3.animation_length).timeout
			NormalsDatabase.ClearDatabase()
			NormalsDatabase.GameSetup()
	canAct = true


func ResetBoard():
	#print("Activating level: " + str(currentLevel))
	#for key in NormalsDatabase.active_database.keys():
		#ActivateTile(key, true)
	#await get_tree().create_timer(worldReference.pillar_set_L3.animation_length).timeout
	print("Activating level: " + str(currentLevel))
	for key in NormalsDatabase.active_database.keys():
		if NormalsDatabase.active_database[key]:
			ActivateTile(key, true)
	print("Activating level: " + str(currentLevel))
	await get_tree().create_timer(worldReference.pillar_set_L3.animation_length).timeout
	currentLevel -= 1
	for key in NormalsDatabase.active_database.keys():
		ActivateTile(key, true)
	await get_tree().create_timer(worldReference.pillar_set_L2.animation_length).timeout
	currentLevel -= 1
	print("Activating level: " + str(currentLevel))
	for key in NormalsDatabase.active_database.keys():
		ActivateTile(key, true)
	await get_tree().create_timer(worldReference.pillar_set_L1.animation_length).timeout
	currentLevel -= 1
	#NormalsDatabase.ClearDatabase()
	#NormalsDatabase.GameSetup()


func ActivateTile(tile : String, end : bool = false):
	if !end:
		if !NormalsDatabase.active_database[tile]:
			# print("Trying to activate: " + tile + " : " + str(NormalsDatabase.normals_database[tile]))
			currentActive += 1
			worldReference.ActivatePillarByNormal(NormalsDatabase.normals_database[tile], currentLevel)
			NormalsDatabase.active_database[tile] = !NormalsDatabase.active_database[tile]
	else:
		worldReference.ActivatePillarByNormal(NormalsDatabase.normals_database[tile], currentLevel)
		NormalsDatabase.active_database[tile] = false
		currentActive = 0


func get_dir() -> Vector3:
	var dir : Vector3 = Vector3.ZERO
	var fowardDir : Vector3 = ( camTarget.global_transform.origin - head.global_transform.origin  ).normalized()
	var dirBase :Vector3= avgNormal.cross( fowardDir ).normalized()
	var inputLeftRight = Input.get_axis("MoveLeft","MoveRight")
	var inputForwardBack = Input.get_axis("MoveBackward","MoveForward")

	var rawInput = Vector2(inputLeftRight, -inputForwardBack)
	var input = Vector3(rawInput.x, 0, rawInput.y)
	if canAct:
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
		basis = basis.get_rotation_quaternion().slerp(rotationBasis, delta * rotationSpeed)

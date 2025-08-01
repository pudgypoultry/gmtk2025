extends CharacterBody3D

@export_category("Game Rules")
@export var rotationSpeed : float = 5.0
@export var verticalCameraClamp : float = 75
@export var speed : float = 5
@export var runSpeed : float = 10
@export var maxTileLineLength : int = 10

@export_category("Plugging in Nodes")
@export var head : Node3D
@export var camera : Node3D
@export var camTarget : Node3D
@export var rayFolder : Node3D
@export var downRayFolder : Node3D
@export var forwardRayFolder : Node3D
@export var downForwardRayFolder : Node3D

var gravity := Vector3(0,-3,0)
var jumpVec := Vector3(0, 75, 0)
var avgNormal : Vector3 = Vector3.ZERO
var MOUSE_SENS := 0.005
var baseSpeed
var extravelocity := Vector3.ZERO
var jumpVectors := Vector3.ZERO
var bodyOn : StaticBody3D
var currentTarget : Node3D = null
var mouseSensMulti := 1
var tempDict : Dictionary = {}

var visitedTiles : Array = []


func _ready() -> void:
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
	#for ray in downRayFolder.get_children():
		#var r : RayCast3D = ray
		#if r.is_colliding():
			#numOfRaysColliding += 1
			#avgNor += r.get_collision_normal()
			#print("Down Normal: " + str(r.get_collision_normal()))
	#for ray in forwardRayFolder.get_children():
		#var r : RayCast3D = ray
		#if r.is_colliding():
			#numOfRaysColliding += 1
			#avgNor += r.get_collision_normal()
			#forwardColliding = true
	#if !forwardColliding:
		#for ray in downForwardRayFolder.get_children():
			#var r : RayCast3D = ray
			#if r.is_colliding():
				#numOfRaysColliding += 1
				#avgNor += r.get_collision_normal()
				#print("DownForward Normal: " + str(r.get_collision_normal()))
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
	OrientCharacterToDirection(up_direction, delta)
	velocity = speed * get_dir()
	checkRays()
	if not is_on_floor():
		jumpVectors += gravity
#		avgNormal = Vector3.UP
	elif is_on_floor():
		jumpVectors = Vector3.ZERO
	velocity += jumpVectors
	up_direction = avgNormal.normalized()
	move_and_slide()


func ManageVisitedTiles():
	pass


func SteppedOnNewTile():
	pass
	# if up_direction changes AND new up_direction is contained in the tile dictionary,
	#	then I stepped on a new tile for sure
	# First, check that that tile is not in the array already
	#	If it is, initiate check for successful loop
	#	Otherwise, light it up and keep going


func CheckForLoop():
	pass
	# Check to see if there are any tiles that have been looped


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

extends CharacterBody3D

enum CharacterState {GRAPPLING, MOVING, FALLING}

@export_category("Game Rules")
@export var rotationSpeed : float = 5.0
@export var verticalCameraClamp : float = 89
@export var speed : float = 5
@export var runSpeed : float = 10
@export var characterHeight : float = 2


@export_category("Plugging in Nodes")
@export var head : Node3D
@export var camera : Node3D
@export var camTarget : Node3D
@export var rayFolder : Node3D
@export var grappleLine : GrappleLine
@export var grappleRay : RayCast3D
# @export var meshAnimation : Node3D
# @export var spawnRay : RayCast3D


var gravity := Vector3(0,-3,0)
var jumpVec := Vector3(0, 75, 0)
var avgNormal : Vector3 = Vector3.UP
var MOUSE_SENS := 0.005
var baseSpeed
var jumpNum := 0
var maxJumpAmt := 10
var extravelocity := Vector3.ZERO
var theUpDir := Vector3.UP
var jumpVectors := Vector3.ZERO
var bodyOn : StaticBody3D
var currentTarget : Node3D = null
var mouseSensMulti := 1
var lastGravity : Vector3 = Vector3.ZERO
var currentState : CharacterState = CharacterState.MOVING
var grapplePoint : Vector3 = Vector3.ZERO
var grappleSpeedFactor : float = 1.0
var grappleDrawInFactor : float = 1.0
var lastVelocity : Vector3 = Vector3.ZERO
var lastUpDirection : Vector3 = Vector3.UP
var justGrappled : bool = false


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
		head.rotation.y += -event.relative.x * MOUSE_SENS * mouseSensMulti
		# meshAnimation.rotation.y += -event.relative.x * MOUSE_SENS * mouseSensMulti
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
	else: # come back and showcase this
		avgNormal = lastGravity
		jumpVec = avgNormal * 50
		gravity = avgNormal * -3


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Reset"):
		get_tree().reload_current_scene()
	#if overWebbing:
		#speed = runSpeed
	#else:
		#speed = baseSpeed
	if Input.is_key_pressed(KEY_ESCAPE):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#
#func jump() -> void:
	#jumpVectors += jumpVec
	#avgNormal = lastGravity
	#jumpVec = avgNormal * 50
	#gravity = avgNormal * -3


func _physics_process(delta: float) -> void:
	OrientCharacterToDirection(up_direction, delta)
	ManageStateBehavior(delta, currentState)
	move_and_slide()



func get_dir() -> Vector3:
	var dir : Vector3 = Vector3.ZERO
	var fowardDir : Vector3 = ( camTarget.global_transform.origin - head.global_transform.origin  ).normalized()
	var dirBase :Vector3= avgNormal.cross( fowardDir ).normalized()
	#var inputLeftRight = Input.get_axis("MoveLeft","MoveRight")
	#var inputForwardBack = Input.get_axis("MoveBackward","MoveForward")
		# Spider Animation
	# var animationTree : AnimationTree
	# animationTree = meshAnimation.Anim_Tree
	# var current_blend_pos : Vector2 = animationTree.get("parameters/blend_position")
	#var rawInput = Vector2(inputLeftRight, -inputForwardBack)
	#var input = Vector3(rawInput.x, 0, rawInput.y)
	# animationTree.set("parameters/blend_position", Vector2(lerp(current_blend_pos.x, rawInput.x, 0.3), lerp(current_blend_pos.y, -rawInput.y, 0.3)))
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


func ManageStateBehavior(delta : float, currentState : CharacterState):
	match currentState:
		CharacterState.MOVING:
			velocity = speed * get_dir() * delta
			if not is_on_floor():
				jumpVectors += gravity
			else:
				checkRays()
				jumpVectors = Vector3.ZERO
				lastGravity = gravity
			#if Input.is_action_just_pressed("Jump"):
				#jump() 
			if Input.is_action_just_pressed("Run"):
				speed = runSpeed
			if Input.is_action_just_released("Run"):
				speed = baseSpeed
			if Input.is_action_just_pressed("Grapple"):
				if grappleRay.is_colliding():
					grapplePoint = grappleRay.get_collision_point()
					lastVelocity = velocity
					HandleStateChange(CharacterState.GRAPPLING)
					return
			velocity += jumpVectors
			up_direction = avgNormal.normalized()
		
		CharacterState.GRAPPLING:
			# grappleLine.SetPathEnds(position, grapplePoint - position)
			#if is_on_floor():
				#HandleStateChange(CharacterState.MOVING)
			#else:
			# TODO: solve for any direction, not just forward
			# TODO: use cross product of current up_direction vs original up_direction to detect how many times we've looped
			if justGrappled:
				justGrappled = false
				position += up_direction * characterHeight
			up_direction = (grapplePoint - position).normalized()
			velocity += jumpVectors
			velocity = -basis.z * grappleSpeedFactor * delta
			velocity += up_direction * grappleDrawInFactor * delta
			grappleSpeedFactor += delta * 10
			grappleDrawInFactor += delta * 50
			lastVelocity = velocity
			if Input.is_action_just_released("Grapple"):
				lastUpDirection = up_direction
				HandleStateChange(CharacterState.FALLING)
		
		CharacterState.FALLING:
			if is_on_floor() or is_on_wall() or is_on_ceiling():
				HandleStateChange(CharacterState.MOVING)
			else:
				velocity = lastVelocity
				up_direction = lastUpDirection
				if Input.is_action_just_pressed("Grapple"):
					if grappleRay.is_colliding():
						grapplePoint = grappleRay.get_collision_point()
						HandleStateChange(CharacterState.GRAPPLING)


func HandleStateChange(newState : CharacterState):
	match newState:
		CharacterState.MOVING:
			grappleLine.visible = false
			grappleSpeedFactor = 1.0
			grappleDrawInFactor = 1.0
		CharacterState.GRAPPLING:
			# grappleLine.visible = true
			justGrappled = true
			grappleSpeedFactor = speed
			grappleLine.SetPathEnds(position, grapplePoint)
		CharacterState.FALLING:
			pass
			# grappleLine.visible = false
	currentState = newState

extends Node
class_name MovementManager

@export var nav_rays: Node3D
@export var eye_minion: Node3D
@export var move_time:float = 2.0
@export var rotation_rays: Node3D

var ray_counter = 0
var ray_list = []
var backAxis:Vector3

func _ready() -> void:
	backAxis = eye_minion.basis.z
	for child in nav_rays.get_children():
		if child is RayCast3D:
			ray_list.append(child)

# gets the next ray to check
func GetNextRay() -> RayCast3D:
	if ray_counter < ray_list.size():
		ray_counter += 1
		return ray_list[ray_counter - 1]
	else:
		ray_counter = 1
		return ray_list[ray_counter - 1]

# returns the key string of the tile normal (for use with normals database) or an empty string
func TryGetTile(ray:RayCast3D) -> String:
	# attmpts to find the tile pointed to by the input ray
	if ray.is_colliding():
		var layer_name:String
		if eye_minion.player.currentLevel - 1 == 0:
			layer_name = "shell"
		elif eye_minion.player.currentLevel - 1 == 0:
			layer_name = "1"
		elif eye_minion.player.currentLevel - 1 == 0:
			layer_name = "2"
		elif eye_minion.player.currentLevel - 1 == 0:
			layer_name = "3"
		else:
			layer_name = "4"
			
		if ray.get_collider().get_parent().name.contains(layer_name):
			# get the collision normal
			var str:String = NormalsDatabase.NormalToKey(ray.get_collision_normal())
			# check if normal is in the normals database
			if str in NormalsDatabase.normals_database.keys():
				# found normal
				return str
	return ""

func RotateToFloor(delta:float, rotationSpeed:float=1.0) -> void:
	for ray in rotation_rays.get_children():
		if ray is RayCast3D and ray.is_colliding():
			var target_up : Vector3 = ray.get_collision_normal()
			var rightAxis : Vector3 = -backAxis.cross(target_up)
			if rightAxis == Vector3.ZERO or backAxis == Vector3.ZERO:
				backAxis = Vector3.BACK
				rightAxis = -backAxis.cross(target_up)
			var rotationBasis := Basis(rightAxis, target_up, backAxis).orthonormalized()
			#print(target_up, rightAxis, backAxis)
			eye_minion.basis = eye_minion.basis.get_rotation_quaternion().slerp(
				rotationBasis,
				delta * rotationSpeed)
			#backAxis = eye_minion.basis.z
			return
	
# Casts a ray from the origin to the shell or pillars and 
# tweens the Eye’s position from where it is, to the ray's intersection point.
# Also tweens the Eye’s rotation so that its current up direction matches the normal of the ray intersection point.
func MoveToTile(tile_id:String) -> void:
	ray_counter = 0
	if tile_id in NormalsDatabase.normals_database.keys():
		var tile_normal:Vector3 = NormalsDatabase.normals_database[tile_id]
		# get target coordinates
		# NOTE target may not be on the shell, can't use position database
		var result = NormalsDatabase.PhysicsProcessRaycast(Vector3.ZERO, -tile_normal * 50, NormalsDatabase.full_collision_mask)
		if result:
			var target_position:Vector3 = result.position
			var target_up:Vector3 = result.normal
			backAxis = (eye_minion.position - target_position).normalized()
			# tween location
			TweenTools.TweenPosition(eye_minion, eye_minion, target_position, move_time)
		

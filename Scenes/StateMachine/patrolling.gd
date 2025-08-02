extends State
@onready var movement_manager: MovementManager = $"../../MovementManager"
var is_moving:bool = false
var reset_collision_mask:int = pow(2, 12-1)

func Enter(old_state:State) -> void:
	super(old_state)
	var local_up:Vector3 = movement_manager.eye_minion.basis.y
	# move to ground
	var result = NormalsDatabase.PhysicsProcessRaycast(movement_manager.eye_minion.position, -local_up * 100, reset_collision_mask)
	if result:
		#print("Current Eye position", movement_manager.eye_minion.position)
		#print("Reset Eye position ", result.position)
		#print("target collision: ", result.collider.get_parent().name)
		movement_manager.eye_minion.position = result.position
	else:
		print("Failed to reset Eye position")
	
func Exit(new_state:State) -> void:
	super(new_state)
	
func Update(_delta) -> void:
	super(_delta)

func Physics_Update(_delta) -> void:
	super(_delta)
	if not is_moving:
		var tile_id:String
		# find next tile to move to
		for i in movement_manager.ray_list.size():
			# get ray
			var ray = movement_manager.GetNextRay()
			tile_id = movement_manager.TryGetTile(ray)
			# check if the result is not empty
			if tile_id.length() > 0:
				# move to tile
				is_moving = true
				movement_manager.MoveToTile(tile_id)
				await get_tree().create_timer(movement_manager.move_time).timeout
				is_moving = false
				return

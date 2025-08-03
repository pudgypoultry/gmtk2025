extends State
@onready var movement_manager: MovementManager = $"../../MovementManager"
@export var stuck: State
@export var hunting: State
@export var hunting_rays: Node3D
var is_moving:bool = false
var found_path:bool = false
var path_id:String

func Enter(old_state:State) -> void:
	super(old_state)
	path_id = ""
	
func Exit(new_state:State) -> void:
	super(new_state)
	found_path = false
	is_moving = false
	
func Update(_delta) -> void:
	super(_delta)
	for ray in hunting_rays.get_children():
		if ray is RayCast3D and ray.is_colliding():
			# path found
			path_id = NormalsDatabase.PositionToKey(ray.get_collider().get_parent().position)
			found_path = true
	

func Physics_Update(_delta) -> void:
	super(_delta)
	if not is_moving:
		if found_path:
			print("Passing pathID: " + path_id)
			hunting.Enter(self)
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
		# none of the ray directions worked, transistion to Stuck
		stuck.Enter(self)

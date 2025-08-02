extends State
@onready var movement_manager: MovementManager = $"../../MovementManager"
@export var stuck: State
var is_moving:bool = false


func Enter(old_state:State) -> void:
	super(old_state)
	
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
		# none of the ray directions worked, transistion to Stuck
		stuck.Enter(self)

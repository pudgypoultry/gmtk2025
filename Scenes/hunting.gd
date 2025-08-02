extends State

@onready var movement_manager: MovementManager = $"../../MovementManager"
@export var patrolling: State
@export var hunting_rays: Node3D
var current_path_id:String
var is_moving:bool = false
var player:CharacterBody3D

func Enter(old_state:State) -> void:
	super(old_state)
	current_path_id = old_state.path_id
	player = movement_manager.eye_minion.player
	
func Exit(new_state:State) -> void:
	super(new_state)
	
func Update(_delta) -> void:
	super(_delta)

func Physics_Update(_delta) -> void:
	super(_delta)
	if not is_moving:
		is_moving = true
		movement_manager.MoveToTile(current_path_id)
		# find current path id in player visited list
		var index:int = player.visitedTileNormals.find(NormalsDatabase.normals_database[current_path_id])
		var obj_index = FindHighlightIndex()
		if index == -1 or obj_index == -1:
			# did not find path
			patrolling.Enter(self)
			return
			
		var tmp_id:String
		if not index + 1 > player.visitedTileNormals.size():
			tmp_id = NormalsDatabase.NormalToKey(player.visitedTileNormals[index + 1])
		# remove it from list
		player.visitedTileNormals.remove_at(index)
		player.visitedTilePositions.remove_at(index)
		# remove object form world
		player.debugArray.remove_at(index)
		
		# set current path id to next value
		if tmp_id:
			current_path_id = tmp_id
		else:
			# if no next value, transition back to patrolling
			patrolling.Enter(self)
		# wait for move to finish
		await get_tree().create_timer(movement_manager.move_time).timeout
		is_moving = false

func FindHighlightIndex() -> int:
	var position:Vector3 = NormalsDatabase.positions_database[current_path_id]
	var count:int = 0
	for obj in player.debugArray:
		if position.dot(obj.position) > 0.99:
			# vectors are the same
			return count
		count += 1
	return -1

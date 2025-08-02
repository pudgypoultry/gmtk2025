extends State
@onready var movement_manager: MovementManager = $"../../MovementManager"
@export var patrolling: State
@export var fly_time:float
var target_position:Vector3
var active_substate:bool = false
enum SUBSTATE {MoveToOrigin, GetTile, MoveToTile, Exit}
var sub_state:SUBSTATE = SUBSTATE.MoveToOrigin

func Enter(old_state:State) -> void:
	super(old_state)

func Exit(new_state:State) -> void:
	super(new_state)
	active_substate = false
	sub_state = SUBSTATE.MoveToOrigin
	
func Update(_delta) -> void:
	super(_delta)
	if active_substate:
		return
	if sub_state == SUBSTATE.MoveToOrigin:
		active_substate = true
		#print("Stuck, moving to Origin")
		await MoveToPosition(Vector3.ZERO)
		active_substate = false
		sub_state = SUBSTATE.GetTile
	elif sub_state == SUBSTATE.GetTile:
		active_substate = true
		# pick a random tile
		#print("Stuck, getting new tile")
		target_position = await GetRandomTilePosition()
		active_substate = false
		sub_state = SUBSTATE.MoveToTile
	elif sub_state == SUBSTATE.MoveToTile:
		active_substate = true
		#print("Stuck, moving to new tile: ", target_position)
		await MoveToPosition(target_position)
		active_substate = false
		sub_state = SUBSTATE.Exit
	elif sub_state == SUBSTATE.Exit:
		active_substate = true
		# enter patrolling state
		patrolling.Enter(self)

func Physics_Update(_delta) -> void:
	super(_delta)

func MoveToPosition(position:Vector3) -> void:
	# move to tile
	TweenTools.TweenPosition(
		movement_manager.eye_minion, 
		movement_manager.eye_minion, 
		position, 
		fly_time)
	await get_tree().create_timer(fly_time*2).timeout

func GetRandomTilePosition() -> Vector3:
	# get the keys in random order
	var tiles:Array = NormalsDatabase.normals_database.keys()
	randomize()
	tiles.shuffle()
	print(tiles.size())
	var counter:int = 0
	for key in tiles:
		# TODO if tile is active continue
		# get good tile location
		var result = NormalsDatabase.PhysicsProcessRaycast(
			Vector3.ZERO, 
			-NormalsDatabase.normals_database[key]*200, 
			movement_manager.eye_minion.full_collision_mask)
		if result:
			return result.position
	print(counter)
	# no valid tiles were found
	return Vector3.ZERO
	

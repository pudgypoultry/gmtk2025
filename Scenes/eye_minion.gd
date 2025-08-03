extends Node3D

class_name EyeMinion

@export var eye_minion_mesh:Node3D
var player:CharacterBody3D
var eye_minion_anim: AnimationPlayer
@onready var movement_manager: MovementManager = $MovementManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# find the animation player
	for child in eye_minion_mesh.get_children():
		if is_instance_of(child, AnimationPlayer):
			eye_minion_anim = child
			break
	if eye_minion_anim:
		#print("playing eye animation")
		eye_minion_anim.play("ArmatureAction")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	movement_manager.RotateToFloor(delta)

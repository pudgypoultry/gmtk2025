extends Node3D

@onready var eye_minion: Node3D = $EyeMinion
var eye_minion_anim: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# find the animation player
	for child in eye_minion.get_children():
		if is_instance_of(child, AnimationPlayer):
			eye_minion_anim = child
			break
	if eye_minion_anim:
		print("playing eye animation")
		eye_minion_anim.play("ArmatureAction")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

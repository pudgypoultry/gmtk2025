extends Node3D

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func activate(duration:float) -> void:
	audio_stream_player_3d.play()
	await get_tree().create_timer(duration).timeout
	audio_stream_player_3d.stop()
	self.queue_free()

extends Button

@export var nextScene : String

func _on_pressed() -> void:
	get_tree().change_scene_to_file(nextScene)

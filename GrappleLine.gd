@tool
extends Node3D
class_name GrappleLine

@export var csgPolygon : CSGPolygon3D
@export var path : Path3D
@export var lineRadius : float = 0.1
@export var lineResolution : int = 180

func _process(delta: float) -> void:
	var circle = PackedVector2Array()
	for degree in lineResolution:
		var x = lineRadius * sin(PI * 2 * degree / lineResolution)
		var y = lineRadius * cos(PI * 2 * degree / lineResolution)
		var coords = Vector2(x,y)
		circle.append(coords)
	csgPolygon.polygon = circle


func SetPathEnds(startPoint : Vector3, endPoint : Vector3):
	path.curve.set_point_position(0, startPoint)
	path.curve.set_point_position(1, endPoint)

extends Node2D

var enemigo = preload("res://Scenes/enemigo1.tscn")

func _on_timer_timeout() -> void:
	var e = enemigo.instantiate() 
	var position = Vector2(
		randf_range($x1.global_position.x, $x2.global_position.x),
		randf_range($y1.global_position.y, $y2.global_position.y)
	)
	
	add_child(e)
	e.global_position = position

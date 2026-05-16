extends CharacterBody2D


@export var speed: float = 200 


func _physics_process(delta: float) -> void:
	
	if Global.Player == null : return
	var Direction: Vector2 = global_position.direction_to(Global.Player.global_position)
	
	
	velocity= Direction.normalized() * speed
	
	move_and_slide()

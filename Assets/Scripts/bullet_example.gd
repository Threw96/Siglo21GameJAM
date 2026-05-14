extends CharacterBody2D


var Direction: Vector2
@export var speedBullet := 400
@export var damageAmount := 1

func _physics_process(delta: float) -> void:
	velocity = Direction.normalized() * speedBullet
	
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		body.TakeDamage(damageAmount)

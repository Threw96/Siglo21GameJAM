extends Area2D

@export var experience_amount: float = 25.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_experience_amount(amount: float) -> void:
	experience_amount = maxf(amount, 0.0)

func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("add_experience"):
		return
	body.add_experience(experience_amount)
	queue_free()

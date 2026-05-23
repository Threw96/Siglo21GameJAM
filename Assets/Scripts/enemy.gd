extends CharacterBody2D
class_name Enemy

@export var speed: float = 200.0
@export var max_health: float = 3.0
@export var experience_value: float = 25.0
@export var gem_scene: PackedScene = preload("res://Scenes/Gema.tscn")
@export var damage: int = 1

var health: float

func _ready() -> void:
	add_to_group("Enemy")
	health = max_health

func TakeDamage(damage_amount: float) -> void:
	health -= damage_amount
	Global.debug_log("%s vida: %s / %s" % [name, health, max_health])
	if health <= 0.0:
		_die()

func _die() -> void:
	_drop_gem()
	queue_free()

func _drop_gem() -> void:
	if gem_scene == null:
		return
	var gem: Node2D = gem_scene.instantiate() as Node2D
	if gem == null:
		return
	if gem.has_method("set_experience_amount"):
		gem.set_experience_amount(experience_value)
	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(gem)
	gem.global_position = global_position

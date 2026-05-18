extends CharacterBody2D
class_name BabyAllien

@export var speed: float = 200 
@export var max_health: float = 3.0
@export var experience_value: float = 25.0
@export var gem_scene: PackedScene = preload("res://Scenes/Gema.tscn")
@export var damage: int = 1

var canAttack: bool = false
var health: float

func _ready() -> void:
	add_to_group("Enemy")
	health = max_health


func _physics_process(delta: float) -> void:
	
	if Global.Player == null : return
	
	if canAttack:
		Attack()
	else:
		Move()

func Move():
	var Direction: Vector2 = global_position.direction_to(Global.Player.global_position)
	velocity= Direction.normalized() * speed
	move_and_slide()
	
func Attack():
	if $Timer.time_left > 0: return
	Global.Player.TakeDamage(damage)
	$Timer.start()
	
func TakeDamage(damage_amount: float) -> void:
	health -= damage_amount
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


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		canAttack = true
	
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		canAttack = false

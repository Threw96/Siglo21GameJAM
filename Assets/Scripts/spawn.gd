extends Node2D

@export var enemigo: PackedScene = preload("res://Scenes/enemigo1.tscn")
@export var boss_scene: PackedScene = preload("res://Scenes/BossRobot.tscn")
@export var base_wait_time: float = 1.2
@export var min_wait_time: float = 0.2
@export var wait_time_decrease_per_minute: float = 0.25
@export var extra_enemy_per_minute: int = 1
@export var enemy_health_growth_per_minute: float = 0.25
@export var enemy_damage_growth_per_minute: float = 0.15
@export var spawn_outside_camera: bool = true
@export var boss_spawn_interval_seconds: float = 300.0

@onready var timer: Timer = get_parent().get_node_or_null("Timer") as Timer

var next_boss_spawn_time: float = 300.0
var active_boss: Enemy

func _ready() -> void:
	next_boss_spawn_time = boss_spawn_interval_seconds
	if timer != null:
		timer.wait_time = base_wait_time

func _on_timer_timeout() -> void:
	if _has_active_boss():
		return
	if Global.survived_time >= next_boss_spawn_time:
		_spawn_boss()
		return
	var minutes: float = Global.survived_time / 60.0
	var amount: int = 1 + int(floor(minutes * float(extra_enemy_per_minute)))
	for index in range(amount):
		_spawn_enemy(minutes)
	_update_timer(minutes)

func _spawn_enemy(minutes: float) -> void:
	var enemy: Node2D = enemigo.instantiate() as Node2D
	if enemy == null:
		return
	if enemy is Enemy:
		var typed_enemy: Enemy = enemy as Enemy
		typed_enemy.max_health *= 1.0 + minutes * enemy_health_growth_per_minute
		typed_enemy.damage = maxi(1, roundi(float(typed_enemy.damage) * (1.0 + minutes * enemy_damage_growth_per_minute)))
		typed_enemy.experience_value *= 1.0 + minutes * 0.1
	add_child(enemy)
	enemy.global_position = _get_spawn_position()

func _spawn_boss() -> void:
	if boss_scene == null:
		next_boss_spawn_time += boss_spawn_interval_seconds
		return
	var boss: Enemy = boss_scene.instantiate() as Enemy
	if boss == null:
		next_boss_spawn_time += boss_spawn_interval_seconds
		return
	active_boss = boss
	add_child(boss)
	boss.global_position = _get_spawn_position()
	if not boss.died.is_connected(_on_boss_died):
		boss.died.connect(_on_boss_died)
	Global.debug_log("Boss spawneado en %s segundos" % Global.survived_time)

func _on_boss_died(_boss: Enemy) -> void:
	active_boss = null
	next_boss_spawn_time = _get_next_boss_spawn_time()
	Global.debug_log("Boss derrotado. Proximo boss en %s segundos" % next_boss_spawn_time)

func _has_active_boss() -> bool:
	return active_boss != null and is_instance_valid(active_boss)

func _get_next_boss_spawn_time() -> float:
	var next_time: float = next_boss_spawn_time + boss_spawn_interval_seconds
	while next_time <= Global.survived_time:
		next_time += boss_spawn_interval_seconds
	return next_time

func _update_timer(minutes: float) -> void:
	if timer == null:
		return
	timer.wait_time = maxf(min_wait_time, base_wait_time - minutes * wait_time_decrease_per_minute)

func _get_spawn_position() -> Vector2:
	if spawn_outside_camera and Global.Player != null and is_instance_valid(Global.Player):
		return _get_spawn_position_outside_camera()
	return Vector2(
		randf_range($x1.global_position.x, $x2.global_position.x),
		randf_range($y1.global_position.y, $y2.global_position.y)
	)

func _get_spawn_position_outside_camera() -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var camera: Camera2D = get_viewport().get_camera_2d()
	var center: Vector2 = Global.Player.global_position
	if camera != null:
		center = camera.global_position
	var margin: float = 80.0
	var half_size: Vector2 = viewport_size * 0.5
	var side: int = randi_range(0, 3)
	match side:
		0:
			return center + Vector2(randf_range(-half_size.x, half_size.x), -half_size.y - margin)
		1:
			return center + Vector2(randf_range(-half_size.x, half_size.x), half_size.y + margin)
		2:
			return center + Vector2(-half_size.x - margin, randf_range(-half_size.y, half_size.y))
	return center + Vector2(half_size.x + margin, randf_range(-half_size.y, half_size.y))

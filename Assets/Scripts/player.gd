extends CharacterBody2D
class_name Player

@export var speed: float = 10  
@export var stats: Stats

signal upgrade_choices_ready(choices: Array[StatBuff])

var pending_upgrade_choices: Array[StatBuff] = []

var bullet: PackedScene = preload("res://Scenes/bullet_example.tscn")
var upgrade_menu_scene: PackedScene = preload("res://Scenes/UpgradeMenu.tscn")
var hud_scene: PackedScene = preload("res://Scenes/HUD.tscn")
var hud: Node

@onready var health_bar: ProgressBar = $HealthBar

#texto de prueba para control de version
func _ready() -> void:
	Global.Player = self
	if stats != null:
		if not stats.health_changed.is_connected(_on_stats_health_changed):
			stats.health_changed.connect(_on_stats_health_changed)
		if not stats.leveled_up.is_connected(_on_stats_leveled_up):
			stats.leveled_up.connect(_on_stats_leveled_up)
		if not stats.stats_changed.is_connected(_on_stats_changed):
			stats.stats_changed.connect(_on_stats_changed)
		stats.setup_stats()
		_update_health_bar(stats.health, stats.current_max_health)
		_update_fire_rate()
		_show_hud.call_deferred()

###Funcion de godot en la que se ejecutan las fisicas 
# - En este caso las direcciones estan mapeadas desde el proyecto:
# W = arriba , A= izquierda, D= derecha y S= abajo
# Luego multiplica la direccion por speed y nos da la velocidad hacia donde mover
###
func _physics_process(delta: float) -> void:
	
	var Direction := Input.get_vector("izquierda","derecha","arriba","abajo")
	
	velocity = Direction * _get_current_speed()
	
	move_and_slide()

func Shot() -> void:
	if stats == null:
		return
	var enemies: Array[Node2D] = $Area2D.get_overlapping_bodies()
	var closedEnemy: BabyAllien = null
	var distance: float = INF
	
	for enemy in enemies:
		if enemy.is_in_group("Enemy"):
			var enemy_node: BabyAllien = enemy as BabyAllien
			if enemy_node == null:
				continue
			var enemy_distance: float = global_position.distance_squared_to(enemy_node.global_position)
			if enemy_distance < distance:
				distance = enemy_distance
				closedEnemy = enemy_node
	if closedEnemy == null:
		return

	$Weapon/DoubleBarrelShotgunIcon.look_at(closedEnemy.global_position)
	var b: Node = bullet.instantiate()
	var parent: Node = get_parent()
	if parent == null:
		return
	parent.add_child(b)
	var pos: Vector2 = $Weapon/DoubleBarrelShotgunIcon/pivot.global_position
	if b.has_method("launch"):
		b.call("launch", pos, closedEnemy.global_position, stats.current_attack)
			
	
func add_experience(amount: float) -> void:
	if stats == null:
		return
	stats.add_experience(amount)
	Global.debug_log("Player XP: %s | Nivel: %s | Falta: %s" % [stats.experience, stats.level, stats.get_experience_to_next_level()])

func choose_upgrade(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= pending_upgrade_choices.size():
		return
	var selected_buff: StatBuff = pending_upgrade_choices[choice_index]
	var heal_to_max: bool = selected_buff.stat == Stats.BuffableStats.MAX_HEALTH
	stats.add_buff(selected_buff, heal_to_max)
	pending_upgrade_choices.clear()

func _on_stats_leveled_up(new_level: int, old_level: int) -> void:
	pending_upgrade_choices = _build_upgrade_choices(new_level)
	upgrade_choices_ready.emit(pending_upgrade_choices)
	_show_upgrade_menu.call_deferred(new_level)
	Global.debug_log("Nivel %s alcanzado. Mejoras disponibles: %s" % [new_level, _get_upgrade_choice_names(pending_upgrade_choices)])

func _show_upgrade_menu(new_level: int) -> void:
	var menu: Node = upgrade_menu_scene.instantiate()
	get_tree().root.add_child(menu)
	if menu.has_method("setup"):
		menu.call("setup", self, pending_upgrade_choices, new_level)

func _show_hud() -> void:
	if hud != null and is_instance_valid(hud):
		return
	hud = hud_scene.instantiate()
	get_tree().root.add_child(hud)
	if hud.has_method("setup"):
		hud.call("setup", stats)

func _build_upgrade_choices(new_level: int) -> Array[StatBuff]:
	var amount_scale: float = 1.0 + (float(new_level) * 0.02)
	var upgrade_pool: Array[StatBuff] = [
		StatBuff.new(Stats.BuffableStats.MAX_HEALTH, 15.0 * amount_scale, StatBuff.BuffType.ADD),
		StatBuff.new(Stats.BuffableStats.ATTACK, 0.15, StatBuff.BuffType.MULTIPLY),
		StatBuff.new(Stats.BuffableStats.DEFENSE, 5.0 * amount_scale, StatBuff.BuffType.ADD),
		StatBuff.new(Stats.BuffableStats.MOVE_SPEED, 0.10, StatBuff.BuffType.MULTIPLY),
		StatBuff.new(Stats.BuffableStats.FIRE_RATE, 0.12, StatBuff.BuffType.MULTIPLY),
	]
	var choices: Array[StatBuff] = []
	upgrade_pool.shuffle()
	var choice_count: int = int(min(3, upgrade_pool.size()))
	for index in range(choice_count):
		choices.append(upgrade_pool[index])
	return choices

func _get_upgrade_choice_names(choices: Array[StatBuff]) -> Array[String]:
	var names: Array[String] = []
	for choice in choices:
		var stat_name: String = String(Stats.BuffableStats.keys()[choice.stat]).capitalize()
		var type_name: String = String(StatBuff.BuffType.keys()[choice.buff_type]).capitalize()
		names.append("%s %s %.2f" % [stat_name, type_name, choice.buff_amount])
	return names

func TakeDamage(damage: int) -> void:
	if stats == null:
		return
	$CPUParticles2D.restart()
	stats.health -= damage
	Global.debug_log("Player vida: %s / %s" % [stats.health, stats.current_max_health])
	
	if stats.health <= 0: Die()
	
func Die() -> void:
	queue_free()
	Global.debug_log("mori")

func _on_stats_health_changed(cur_health: float, max_health: float) -> void:
	_update_health_bar(cur_health, max_health)

func _update_health_bar(cur_health: float, max_health: float) -> void:
	if health_bar == null:
		return
	health_bar.max_value = maxf(max_health, 1.0)
	health_bar.value = cur_health

func _on_stats_changed() -> void:
	_update_fire_rate()

func _update_fire_rate() -> void:
	if stats == null:
		return
	$Weapon/cd.wait_time = 1.0 / maxf(stats.current_fire_rate, 0.1)

func _get_current_speed() -> float:
	if stats == null:
		return speed
	return stats.current_move_speed


func _on_cd_timeout() -> void:
	Shot()

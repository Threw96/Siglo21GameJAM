extends CharacterBody2D
class_name Player

@export var speed: float = 10  
@export var stats: Stats

signal upgrade_choices_ready(choices: Array[StatBuff])

var pending_upgrade_choices: Array[StatBuff] = []

var bullet: PackedScene = preload("res://Scenes/bullet_example.tscn")

#texto de prueba para control de version
func _ready() -> void:
	Global.Player = self
	if stats != null:
		stats.leveled_up.connect(_on_stats_leveled_up)
		stats.setup_stats()

###Funcion de godot en la que se ejecutan las fisicas 
# - En este caso las direcciones estan mapeadas desde el proyecto:
# W = arriba , A= izquierda, D= derecha y S= abajo
# Luego multiplica la direccion por speed y nos da la velocidad hacia donde mover
###
func _physics_process(delta: float) -> void:
	
	var Direction := Input.get_vector("izquierda","derecha","arriba","abajo")
	
	velocity = Direction * speed
	
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
	print("Player XP: %s | Nivel: %s | Falta: %s" % [stats.experience, stats.level, stats.get_experience_to_next_level()])

func choose_upgrade(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= pending_upgrade_choices.size():
		return
	stats.add_buff(pending_upgrade_choices[choice_index])
	pending_upgrade_choices.clear()

func _on_stats_leveled_up(new_level: int, old_level: int) -> void:
	pending_upgrade_choices = _build_upgrade_choices(new_level)
	upgrade_choices_ready.emit(pending_upgrade_choices)
	print("Nivel %s alcanzado. Mejoras disponibles: %s" % [new_level, _get_upgrade_choice_names(pending_upgrade_choices)])

func _build_upgrade_choices(new_level: int) -> Array[StatBuff]:
	var amount_scale: float = 1.0 + (float(new_level) * 0.02)
	var choices: Array[StatBuff] = [
		StatBuff.new(Stats.BuffableStats.MAX_HEALTH, 15.0 * amount_scale, StatBuff.BuffType.ADD),
		StatBuff.new(Stats.BuffableStats.ATTACK, 0.15, StatBuff.BuffType.MULTIPLY),
		StatBuff.new(Stats.BuffableStats.DEFENSE, 5.0 * amount_scale, StatBuff.BuffType.ADD),
	]
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
	print("Player vida: %s / %s" % [stats.health, stats.current_max_health])
	
	if stats.health <= 0: Die()
	
func Die() -> void:
	queue_free()
	print("mori")


func _on_cd_timeout() -> void:
	Shot()

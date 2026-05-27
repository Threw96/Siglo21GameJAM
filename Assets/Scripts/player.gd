extends CharacterBody2D
class_name Player

@export var speed: float = 10  
@export var stats: Stats

signal upgrade_choices_ready(choices: Array[StatBuff])

const MAX_UPGRADE_STACKS_PER_STAT: int = 3

var pending_upgrade_choices: Array[StatBuff] = []
var pending_upgrade_levels: Array[int] = []
var upgrade_counts_by_stat: Dictionary[Stats.BuffableStats, int] = {}
var upgrade_menu_active: bool = false

var bullet: PackedScene = preload("res://Scenes/bullet_example.tscn")
var upgrade_menu_scene: PackedScene = preload("res://Scenes/UpgradeMenu.tscn")
var hud_scene: PackedScene = preload("res://Scenes/HUD.tscn")
var hud: Node
var weapons: Array[Weapon] = []
var invulnerability_timer: SceneTreeTimer

@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_range_shape: CollisionShape2D = $Area2D/CollisionShape2D

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
		_update_weapon_range()
		_show_hud.call_deferred()
	_collect_weapons()
	Global.start_run()

###Funcion de godot en la que se ejecutan las fisicas 
# - En este caso las direcciones estan mapeadas desde el proyecto:
# W = arriba , A= izquierda, D= derecha y S= abajo
# Luego multiplica la direccion por speed y nos da la velocidad hacia donde mover
###
func _physics_process(delta: float) -> void:
	
	var Direction := Input.get_vector("izquierda","derecha","arriba","abajo")
	
	velocity = Direction * _get_current_speed()
	
	move_and_slide()
	_tick_weapons(delta)

func Shot() -> void:
	_tick_weapons(999.0)
			
	
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
	_register_upgrade_stack(selected_buff.stat)
	stats.add_buff(selected_buff, heal_to_max)
	pending_upgrade_choices.clear()
	upgrade_menu_active = false
	_show_next_upgrade_menu.call_deferred()

func _on_stats_leveled_up(new_level: int, old_level: int) -> void:
	for level in range(old_level + 1, new_level + 1):
		pending_upgrade_levels.append(level)
	_show_next_upgrade_menu.call_deferred()
	Global.debug_log("Nivel %s alcanzado desde %s. Mejoras en cola: %s" % [new_level, old_level, pending_upgrade_levels.size()])

func _show_next_upgrade_menu() -> void:
	if upgrade_menu_active:
		return
	if pending_upgrade_levels.is_empty():
		get_tree().paused = false
		return
	var next_level: int = int(pending_upgrade_levels.pop_front())
	pending_upgrade_choices = _build_upgrade_choices(next_level)
	if pending_upgrade_choices.is_empty():
		Global.debug_log("No quedan mejoras disponibles para nivel %s" % next_level)
		_show_next_upgrade_menu.call_deferred()
		return
	upgrade_menu_active = true
	upgrade_choices_ready.emit(pending_upgrade_choices)
	var menu: Node = upgrade_menu_scene.instantiate()
	get_tree().root.add_child(menu)
	if menu.has_method("setup"):
		menu.call("setup", self, pending_upgrade_choices, next_level)
	Global.debug_log("Menu nivel %s. Mejoras disponibles: %s" % [next_level, _get_upgrade_choice_names(pending_upgrade_choices)])

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
		StatBuff.new(Stats.BuffableStats.MAX_HEALTH, 15.0 * amount_scale, StatBuff.BuffType.ADD, StatBuff.Rarity.COMMON, 1, "Caldera reforzada"),
		StatBuff.new(Stats.BuffableStats.ATTACK, 0.15, StatBuff.BuffType.MULTIPLY, StatBuff.Rarity.COMMON, 1, "Presion ofensiva"),
		StatBuff.new(Stats.BuffableStats.DEFENSE, 2.0 * amount_scale, StatBuff.BuffType.ADD, StatBuff.Rarity.COMMON, 1, "Placas remachadas"),
		StatBuff.new(Stats.BuffableStats.MOVE_SPEED, 0.03, StatBuff.BuffType.MULTIPLY, StatBuff.Rarity.COMMON, 1, "Botas engrasadas"),
		StatBuff.new(Stats.BuffableStats.FIRE_RATE, 0.12, StatBuff.BuffType.MULTIPLY, StatBuff.Rarity.COMMON, 1, "Valvula rapida"),
		StatBuff.new(Stats.BuffableStats.PICKUP_RANGE, 45.0, StatBuff.BuffType.ADD, StatBuff.Rarity.COMMON, 1, "Iman de chatarra"),
		StatBuff.new(Stats.BuffableStats.WEAPON_RANGE, 40.0, StatBuff.BuffType.ADD, StatBuff.Rarity.RARE, 2, "Mira telescopica"),
		StatBuff.new(Stats.BuffableStats.DAMAGE_REDUCTION, 0.05, StatBuff.BuffType.ADD, StatBuff.Rarity.RARE, 2, "Blindaje de vapor"),
		#StatBuff.new(Stats.BuffableStats.PHYSICAL_RESISTANCE, 0.08, StatBuff.BuffType.ADD, StatBuff.Rarity.RARE, 2, "Amortiguadores"),
		#StatBuff.new(Stats.BuffableStats.ELECTRIC_RESISTANCE, 0.10, StatBuff.BuffType.ADD, StatBuff.Rarity.RARE, 2, "Guantes aislantes"),
		#StatBuff.new(Stats.BuffableStats.FIRE_RESISTANCE, 0.10, StatBuff.BuffType.ADD, StatBuff.Rarity.RARE, 2, "Traje ignifugo"),
		StatBuff.new(Stats.BuffableStats.PROJECTILE_COUNT, 1.0, StatBuff.BuffType.ADD, StatBuff.Rarity.EPIC, 3, "Doble mecanismo"),
	]
	var available_pool: Array[StatBuff] = []
	for buff in upgrade_pool:
		if buff.min_level <= new_level and _can_offer_upgrade(buff):
			available_pool.append(buff)
	var choices: Array[StatBuff] = []
	available_pool.shuffle()
	var choice_count: int = int(min(3, available_pool.size()))
	for index in range(choice_count):
		choices.append(available_pool[index])
	return choices

func _can_offer_upgrade(buff: StatBuff) -> bool:
	return _get_upgrade_stack_count(buff.stat) < MAX_UPGRADE_STACKS_PER_STAT

func _register_upgrade_stack(stat: Stats.BuffableStats) -> void:
	upgrade_counts_by_stat[stat] = _get_upgrade_stack_count(stat) + 1

func _get_upgrade_stack_count(stat: Stats.BuffableStats) -> int:
	return int(upgrade_counts_by_stat.get(stat, 0))

func _get_upgrade_choice_names(choices: Array[StatBuff]) -> Array[String]:
	var names: Array[String] = []
	for choice in choices:
		var stat_name: String = String(Stats.BuffableStats.keys()[choice.stat]).capitalize()
		var type_name: String = String(StatBuff.BuffType.keys()[choice.buff_type]).capitalize()
		names.append("%s %s %.2f" % [stat_name, type_name, choice.buff_amount])
	return names

func TakeDamage(damage: int, damage_type: Stats.DamageType = Stats.DamageType.PHYSICAL) -> void:
	if stats == null:
		return
	var final_damage: float = stats.take_damage(float(damage), damage_type)
	if final_damage > 0.0:
		$CPUParticles2D.restart()
		#_start_invulnerability()
	Global.debug_log("Player recibio %s de dano (%s bruto). Vida: %s / %s" % [final_damage, damage, stats.health, stats.current_max_health])
	
	if stats.health <= 0: Die()
	
func Die() -> void:
	Global.stop_run()
	if Global.Player == self:
		Global.Player = null
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
	_update_weapon_range()

func _update_fire_rate() -> void:
	if stats == null:
		return
	$Weapon/cd.wait_time = 1.0 / maxf(stats.current_fire_rate, 0.1)

func _get_current_speed() -> float:
	if stats == null:
		return speed
	return stats.current_move_speed

func _update_weapon_range() -> void:
	if stats == null or weapon_range_shape == null:
		return
	var circle_shape: CircleShape2D = weapon_range_shape.shape as CircleShape2D
	if circle_shape != null:
		circle_shape.radius = stats.current_weapon_range

func _collect_weapons() -> void:
	weapons.clear()
	for child in get_children():
		if child is Weapon:
			weapons.append(child)

func _tick_weapons(delta: float) -> void:
	if stats == null:
		return
	for weapon in weapons:
		weapon.tick(delta, self, stats)

func _start_invulnerability() -> void:
	stats.set_invulnerable(true)
	invulnerability_timer = get_tree().create_timer(0.6)
	await invulnerability_timer.timeout
	if stats != null:
		stats.set_invulnerable(false)


func _on_cd_timeout() -> void:
	pass

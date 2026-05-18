extends Resource

class_name Stats

enum BuffableStats {
	MAX_HEALTH,
	DEFENSE,
	ATTACK
}

const STAT_CURVES: Dictionary[BuffableStats, Curve] = {
	BuffableStats.MAX_HEALTH: preload("uid://divtg5lq3xjxq"),
	BuffableStats.DEFENSE: preload("uid://c27gscam2eo3x"),
	BuffableStats.ATTACK: preload("uid://cv71swhfj6rm3")
}

const BASE_LEVEL_EXP: float = 100.0

signal health_depleted
signal health_changed(cur_health: float , max_health:float)
signal leveled_up(new_level: int, old_level: int)

@export var base_max_health: float = 100
@export var base_defense: float = 10
@export var base_attack: float = 10
@export var experience: float = 0: set = on_experience_set

var level: int:
	get(): return int(floor(max(1.0,sqrt(experience / BASE_LEVEL_EXP) + 0.5)))
	
var current_max_health: float = 100
var current_defense: float = 10
var current_attack: float = 10
var health: float = 0 : set = _on_health_set

var stat_buffs: Array[StatBuff]

func _init() -> void:
	setup_stats.call_deferred()
	
func setup_stats() -> void:
	var previous_max_health: float = current_max_health
	var previous_health: float = health
	recalculate_stats()
	if previous_health <= 0.0:
		health = current_max_health
	else:
		var health_ratio: float = previous_health / previous_max_health
		health = current_max_health * health_ratio

func add_buff(buff: StatBuff) ->void:
	stat_buffs.append(buff)
	recalculate_stats.call_deferred()
	
func remove_buff(buff: StatBuff) ->void:
	stat_buffs.erase(buff)
	recalculate_stats.call_deferred()
	
	
func recalculate_stats() -> void:
	var stat_multipliers: Dictionary = {}
	var stat_addens: Dictionary = {}
	#recorre los diccionarios de mejoras y le indica como comportarse
	for buff in stat_buffs:
		var stat_name: String = BuffableStats.keys()[buff.stat].to_lower()
		match  buff.buff_type:
			StatBuff.BuffType.ADD:
				if not stat_addens.has(stat_name):
					stat_addens[stat_name] = 0.0
				stat_addens[stat_name] += buff.buff_amount
			StatBuff.BuffType.MULTIPLY:
				if not stat_multipliers.has(stat_name):
					stat_multipliers[stat_name] = 1.0
				stat_multipliers[stat_name] += buff.buff_amount
				
				if stat_multipliers[stat_name] < 0.0:
					stat_multipliers[stat_name] = 0.0
	#stats actuales
	var stat_sample_pos: float = (float(level) / 100.0) -0.01
	current_max_health = base_max_health * _get_curve_multiplier(BuffableStats.MAX_HEALTH, stat_sample_pos)
	current_defense = base_defense * _get_curve_multiplier(BuffableStats.DEFENSE, stat_sample_pos)
	current_attack = base_attack * _get_curve_multiplier(BuffableStats.ATTACK, stat_sample_pos)
	
	#aplica mejoras de nivel por multiplicador
	for stat_name in stat_multipliers:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) *stat_multipliers[stat_name])
	
	#aplica mejoras de nivel por incremento
	for stat_name in stat_addens:
		var cur_property_name: String = str("current_" + stat_name)
		set(cur_property_name, get(cur_property_name) + stat_addens[stat_name])

func _on_health_set(new_value: float) -> void:
	health = clampf(new_value,0,current_max_health)
	health_changed.emit(health,current_max_health)
	if health <= 0:
		health_depleted.emit()

func _get_curve_multiplier(stat: BuffableStats, sample_pos: float) -> float:
	var level_one_sample_pos: float = (1.0 / 100.0) - 0.01
	var level_one_value: float = STAT_CURVES[stat].sample(level_one_sample_pos)
	if is_zero_approx(level_one_value):
		return 1.0
	return STAT_CURVES[stat].sample(sample_pos) / level_one_value

func add_experience(amount: float) -> void:
	experience += maxf(amount, 0.0)

func get_experience_for_level(target_level: int) -> float:
	var normalized_level: float = float(max(target_level, 1)) - 0.5
	return normalized_level * normalized_level * BASE_LEVEL_EXP

func get_experience_to_next_level() -> float:
	return maxf(get_experience_for_level(level + 1) - experience, 0.0)

func on_experience_set(new_value:float ) ->void:
	var old_level: int = level
	experience = maxf(new_value, 0.0)
	
	if not old_level == level:
		recalculate_stats()
		leveled_up.emit(level, old_level)

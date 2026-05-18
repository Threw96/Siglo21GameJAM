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

@export var base_max_health: float = 100
@export var base_defense: float = 10
@export var base_attack: float = 10
@export var experience: float = 0: set = on_experience_set

var level: float:
	get(): return floor(max(1.0,sqrt(experience / BASE_LEVEL_EXP) + 0.5))
	
var current_max_health: float = 100
var current_defense: float = 10
var current_attack: float = 10
var health: float = 0 : set = _on_health_set

var stat_buffs: Array[StatBuff]

func _init() -> void:
	setup_stats.call_deferred()
	
func setup_stats() -> void:
	recalculate_stats()
	health = current_max_health

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
	current_max_health = base_max_health * STAT_CURVES[BuffableStats.MAX_HEALTH].sample((stat_sample_pos))
	current_defense = base_defense * STAT_CURVES[BuffableStats.DEFENSE].sample((stat_sample_pos))
	current_attack = base_attack * STAT_CURVES[BuffableStats.ATTACK].sample((stat_sample_pos))
	
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

func on_experience_set(new_value:float ) ->void:
	var old_level: float = level
	experience = new_value
	
	if not old_level == level:
		recalculate_stats()

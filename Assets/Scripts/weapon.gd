extends Node2D
class_name Weapon

@export var damage_multiplier: float = 1.0
@export var fire_rate_multiplier: float = 1.0
@export var range_multiplier: float = 1.0

var cooldown: float = 0.0

func tick(delta: float, owner: Player, stats: Stats) -> void:
	if cooldown > 0.0:
		cooldown -= delta
		return
	if try_attack(owner, stats):
		var shots_per_second: float = maxf(stats.current_fire_rate * fire_rate_multiplier, 0.1)
		cooldown = 1.0 / shots_per_second

func try_attack(owner: Player, stats: Stats) -> bool:
	return false

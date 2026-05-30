extends ProjectileWeapon
class_name ShotgunWeapon

func _ready() -> void:
	weapon_id = "shotgun"
	display_name = "Shotgun"
	use_player_fire_rate = false
	cooldown_seconds = 1.0

func apply_upgrade(upgrade_stat: Stats.BuffableStats) -> void:
	match upgrade_stat:
		Stats.BuffableStats.SHOTGUN_EXTRA_PROJECTILE:
			extra_projectiles += 1
		Stats.BuffableStats.SHOTGUN_FIRE_RATE:
			cooldown_seconds = 0.7
		Stats.BuffableStats.SHOTGUN_DAMAGE:
			damage_multiplier += 0.25

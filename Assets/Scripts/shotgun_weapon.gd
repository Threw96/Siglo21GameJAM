extends ProjectileWeapon
class_name ShotgunWeapon

func _ready() -> void:
	weapon_id = "shotgun"
	display_name = "Shotgun"

func apply_upgrade(upgrade_stat: Stats.BuffableStats) -> void:
	match upgrade_stat:
		Stats.BuffableStats.SHOTGUN_EXTRA_PROJECTILE:
			extra_projectiles += 1
		Stats.BuffableStats.SHOTGUN_FIRE_RATE:
			fire_rate_multiplier += 0.3
		Stats.BuffableStats.SHOTGUN_DAMAGE:
			damage_multiplier += 0.25

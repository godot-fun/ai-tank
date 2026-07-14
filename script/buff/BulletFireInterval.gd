class_name BulletFireInterval
extends Buff

const BULLET_FIRE_INTERVAL_LEVEL_UP := 0.2
static var min_bullet_fire_interval: float = TankConfig.DEFAULT_BULLET_FIRE_INTERVAL - BULLET_FIRE_INTERVAL_LEVEL_UP * 3

func trigger(tank: Tank) -> void:
	tank.bullet_fire_interval = max(tank.bullet_fire_interval - BULLET_FIRE_INTERVAL_LEVEL_UP, min_bullet_fire_interval)
	pass
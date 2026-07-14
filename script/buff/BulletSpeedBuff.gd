class_name BulletSpeedBuff
extends Buff

const BULLET_SPEED_LEVEL_UP := 200.0
static var max_bullet_speed: float = TankConfig.DEFAULT_BULLET_SPEED + BULLET_SPEED_LEVEL_UP * 3

func trigger(tank: Tank) -> void:
	tank.bullet_speed = min(tank.bullet_speed + BULLET_SPEED_LEVEL_UP, max_bullet_speed)
	pass
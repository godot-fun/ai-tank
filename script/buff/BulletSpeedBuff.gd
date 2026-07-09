class_name BulletSpeedBuff
extends Buff


const MAX_BULLET_SPEED: float = 2000

func trigger(tank: Tank) -> void:
	tank.bullet_speed = min(tank.bullet_speed + 200.0, MAX_BULLET_SPEED)
	pass
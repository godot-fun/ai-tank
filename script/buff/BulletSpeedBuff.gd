class_name BulletSpeedBuff
extends IBuff

const EFFECT_VALUE := 200.0

func trigger(tank: Tank) -> void:
	tank.bullet_speed = tank.bullet_speed + EFFECT_VALUE
	pass

func type() -> BuffType:
	return BuffType.BULLET_SPEED
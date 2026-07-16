class_name BulletSizeBuff
extends IBuff

const EFFECT_VALUE := 0.3

func trigger(tank: Tank) -> void:
	tank.bullet_size = tank.bullet_size + EFFECT_VALUE
	pass

func type() -> BuffType:
	return BuffType.BULLET_SIZE
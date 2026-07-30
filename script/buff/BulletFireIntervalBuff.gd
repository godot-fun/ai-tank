class_name BulletFireIntervalBuff
extends IBuff

const EFFECT_VALUE := 0.2

func trigger(tank: Tank) -> void:
	tank.bullet_fire_interval = tank.bullet_fire_interval - EFFECT_VALUE
	pass

static func type() -> BuffType:
	return BuffType.BULLET_FIRE_INTERVAL

static func new_buff() -> IBuff:
	return BulletFireIntervalBuff.new()

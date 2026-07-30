class_name TankSpeedBuff
extends IBuff

const EFFECT_VALUE := 50.0

func trigger(tank: Tank) -> void:
	tank.speed = tank.speed + EFFECT_VALUE
	pass

static func type() -> BuffType:
	return BuffType.TANK_SPEED

static func new_buff() -> IBuff:
	return TankSpeedBuff.new()

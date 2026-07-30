class_name TankRespawnBuff
extends IBuff

const EFFECT_VALUE := 1.5

func trigger(tank: Tank) -> void:
	pass

static func type() -> BuffType:
	return BuffType.TANK_RESPAWN
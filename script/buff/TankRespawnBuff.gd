class_name TankRespawnBuff
extends IBuff

const EFFECT_VALUE := 2.0

func trigger(tank: Tank) -> void:
	pass

func type() -> BuffType:
	return BuffType.TANK_RESPAWN
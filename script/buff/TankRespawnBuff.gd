class_name TankRespawnBuff
extends IBuff

const EFFECT_VALUE := 1.5

func trigger(tank: Tank) -> void:
	pass

func type() -> BuffType:
	return BuffType.TANK_RESPAWN

func new_buff() -> IBuff:
	return TankRespawnBuff.new()

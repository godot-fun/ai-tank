class_name TankSizeBuff
extends IBuff

const EFFECT_VALUE := Vector2i(1, 1)

func trigger(tank: Tank) -> void:
	tank.grid_size = EFFECT_VALUE
	tank.scale_tank()
	pass

func type() -> BuffType:
	return BuffType.TANK_SIZE
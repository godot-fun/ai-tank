class_name TankSizeBuff
extends IBuff

const EFFECT_VALUE := Vector2i(1, 1)

func trigger(tank: Tank) -> void:
	tank.grid_size = EFFECT_VALUE
	tank.scale_tank_deferred()
	pass

static func type() -> BuffType:
	return BuffType.TANK_SIZE

static func new_buff() -> IBuff:
	return TankSizeBuff.new()
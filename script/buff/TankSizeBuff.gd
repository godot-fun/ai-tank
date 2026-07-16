class_name TankSizeBuff
extends Buff

const EFFECT_VALUE := Vector2i(1, 1)

func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	if tank_config.grid_size == EFFECT_VALUE:
		return	
	tank_config.grid_size = EFFECT_VALUE
	tank.grid_size = EFFECT_VALUE
	tank.scale_tank()
	queue_free()
	pass
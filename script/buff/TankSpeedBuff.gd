class_name TankSpeedBuff
extends Buff

const EFFECT_VALUE := 100.0
static var limit: float = TankConfig.DEFAULT_TANK_SPEED + EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	var value := minf(tank_config.speed + EFFECT_VALUE, limit)
	
	tank_config.speed = value
	tank.speed = value
	pass
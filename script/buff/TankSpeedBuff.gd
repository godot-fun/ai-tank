class_name TankSpeedBuff
extends Buff

const EFFECT_VALUE := 100.0
static var limit: float = TankConfig.DEFAULT_TANK_SPEED + EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var value := minf(tank.speed + EFFECT_VALUE, limit)
	tank.speed = value
	
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	tank_config.speed = value
	pass
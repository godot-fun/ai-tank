class_name BulletSpeedBuff
extends Buff

const EFFECT_VALUE := 200.0
static var limit: float = TankConfig.DEFAULT_BULLET_SPEED + EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	var value := minf(tank_config.bullet_speed + EFFECT_VALUE, limit)
	
	tank_config.bullet_speed = value
	tank.bullet_speed = value
	pass
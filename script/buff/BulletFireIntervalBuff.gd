class_name BulletFireIntervalBuff
extends Buff

const EFFECT_VALUE := 0.2
static var limit: float = TankConfig.DEFAULT_BULLET_FIRE_INTERVAL - EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	var value := maxf(tank_config.bullet_fire_interval - EFFECT_VALUE, limit)
	
	tank_config.bullet_fire_interval = value
	tank.bullet_fire_interval = value
	pass
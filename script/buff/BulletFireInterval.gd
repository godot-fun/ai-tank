class_name BulletFireInterval
extends Buff

const BULLET_FIRE_INTERVAL_LEVEL_UP := 0.2
static var min_bullet_fire_interval: float = TankConfig.DEFAULT_BULLET_FIRE_INTERVAL - BULLET_FIRE_INTERVAL_LEVEL_UP * 3

func trigger(tank: Tank) -> void:
	var value := maxf(tank.bullet_fire_interval - BULLET_FIRE_INTERVAL_LEVEL_UP, min_bullet_fire_interval)
	tank.bullet_fire_interval = value
	
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	tank_config.bullet_fire_interval = value
	pass
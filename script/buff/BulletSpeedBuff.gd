class_name BulletSpeedBuff
extends Buff

const BULLET_SPEED_LEVEL_UP := 200.0
static var max_bullet_speed: float = TankConfig.DEFAULT_BULLET_SPEED + BULLET_SPEED_LEVEL_UP * 3

func trigger(tank: Tank) -> void:
	var value := minf(tank.bullet_speed + BULLET_SPEED_LEVEL_UP, max_bullet_speed)
	tank.bullet_speed = value
	
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	tank_config.bullet_speed = value
	pass
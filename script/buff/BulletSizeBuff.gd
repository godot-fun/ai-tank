class_name BulletSizeBuff
extends Buff

const EFFECT_VALUE := 0.3
static var limit: float = TankConfig.DEFAULT_BULLET_SIZE + EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var value := minf(tank.bullet_size + EFFECT_VALUE, limit)
	tank.bullet_size = value
	
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	tank_config.bullet_size = value
	pass
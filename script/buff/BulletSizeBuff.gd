class_name BulletSizeBuff
extends Buff

const BULLET_SIZE_LEVEL_UP := 0.3
static var max_bullet_size: float = TankConfig.DEFAULT_BULLET_SIZE + BULLET_SIZE_LEVEL_UP * 3

func trigger(tank: Tank) -> void:
	var value := minf(tank.bullet_size + BULLET_SIZE_LEVEL_UP, max_bullet_size)
	tank.bullet_size = value
	
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	tank_config.bullet_size = value
	pass
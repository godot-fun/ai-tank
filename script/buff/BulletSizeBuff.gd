class_name BulletSizeBuff
extends Buff

const EFFECT_VALUE := 0.3
static var limit: float = TankConfig.DEFAULT_BULLET_SIZE + EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	var value := minf(tank_config.bullet_size + EFFECT_VALUE, limit)
	if tank_config.bullet_size == limit:
		return
	tank_config.bullet_size = value
	tank.bullet_size = value
	queue_free()
	pass
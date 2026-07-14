class_name TankHpBuff
extends Buff

const EFFECT_VALUE: int = 1
static var limit: int = TankConfig.DEFAULT_TANK_HP + EFFECT_VALUE * 3

func trigger(tank: Tank) -> void:
	var value := mini(tank.hp + EFFECT_VALUE, limit)
	tank.hp = value
	
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	tank_config.hp = value
	pass
class_name TankRespawnBuff
extends Buff

const EFFECT_VALUE := 8.0

func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	if tank_config.team != TankConfig.Team.PLAYER:
		return
	
	if tank_config.id == 0:
		RespawnManager.my_tank_respawn_time = EFFECT_VALUE
	else:
		RespawnManager.partner_tank_respawn_time = EFFECT_VALUE
	pass
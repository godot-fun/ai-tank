class_name TankRespawnBuff
extends Buff

const EFFECT_VALUE := 2.0
static var limit: float = RespawnManager.DEFAULT_RESPAWN_TIME - EFFECT_VALUE * 3


func trigger(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	if tank_config.team != TankConfig.Team.PLAYER:
		return
	
	if tank_config.id == 0:
		var value := maxf(RespawnManager.my_tank_respawn_time - EFFECT_VALUE, limit)
		RespawnManager.my_tank_respawn_time = value
	else:
		var value := maxf(RespawnManager.partner_tank_respawn_time - EFFECT_VALUE, limit)
		RespawnManager.partner_tank_respawn_time = value
	pass
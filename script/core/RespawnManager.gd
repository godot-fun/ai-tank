class_name RespawnManager

static var my_tank_respawn_time: float = 15.0

static var partner_tank_respawn_time: float = 15.0

static func init() -> void:
	EventBus.events.tank_death.connect(on_tank_death)
	pass



static func on_tank_death(id: int) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	if tank_config.team != TankConfig.Team.PLAYER:
		return
	var respawn_time := my_tank_respawn_time if tank_config.id == 0 else partner_tank_respawn_time
	
	SchedulerBus.schedule(on_respawn.bind(tank_config), respawn_time * TimeUtils.MILLIS_PER_SECOND)
	pass


static func on_respawn(tank_config: TankConfig.TankData) -> void:
	pass
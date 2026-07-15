class_name BuffManager

const DEFAULT_RESPAWN_TIME: float = 15.0


static var initialized: bool = false

static func init() -> void:
	if initialized:
		return
	initialized = true
	EventBus.events.enemy_tank_death.connect(on_enemy_tank_death)
	pass



static func on_enemy_tank_death(tank: Tank) -> void:
	var id := tank.id
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[id]
	if tank_config.team == TankConfig.Team.PLAYER:
		return
	if id in range(TankConfig.ENEMY_RED_ID_RANGE.x, TankConfig.ENEMY_RED_ID_RANGE.y):
		gdf.callable_deferred(func() -> void: BuffHelper.create_buff(BuffConfig.random_buff(), tank.grid_pos))
	pass

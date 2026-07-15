class_name RespawnManager

const DEFAULT_RESPAWN_TIME: float = 15.0

static var my_tank_respawn_time: float = DEFAULT_RESPAWN_TIME

static var partner_tank_respawn_time: float = DEFAULT_RESPAWN_TIME

static var initialized: bool = false

static func init() -> void:
	my_tank_respawn_time = DEFAULT_RESPAWN_TIME
	partner_tank_respawn_time = DEFAULT_RESPAWN_TIME
	if initialized:
		return
	initialized = true
	EventBus.events.player_tank_death.connect(on_player_tank_death)
	pass



static func on_player_tank_death(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	if tank_config.team != TankConfig.Team.PLAYER:
		return
	var respawn_time := my_tank_respawn_time if tank_config.id == 0 else partner_tank_respawn_time
	var parent := tank.get_parent()
	RespawnCountdown.spawn(tank.global_position, respawn_time, parent)
	parent.create_tween().tween_callback(on_respawn.bind(tank_config)).set_delay(respawn_time)
	pass


static func on_respawn(tank_config: TankConfig.TankData) -> void:
	if BattleProgress.level_ended:
		return
	if tank_config.id == 0:
		TankHelper.create_tank(tank_config, Eagle.my_tank_start_grid_pos)
	else:
		TankHelper.create_tank(tank_config, Eagle.partner_start_grid_pos)
	Audios.play_sfx(AudioConfig.TANK_RELOAD)
	pass
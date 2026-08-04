class_name BuffManager

const DEFAULT_RESPAWN_TIME: float = 10.0


static var initialized: bool = false

static var buff_map: Dictionary[int, BuffContainer] = {}

static var current_level_buff_map: Dictionary[int, BuffContainer] = {}

## tank_id -> 击杀敌人数
static var enemy_kill_counts: Dictionary[int, int] = {}


static func init() -> void:
	buff_map.clear()
	current_level_buff_map.clear()
	enemy_kill_counts.clear()
	if initialized:
		return
	initialized = true
	EventBus.events.enemy_tank_death.connect(on_enemy_tank_death)
	EventBus.events.player_tank_death.connect(on_player_tank_death)
	EventBus.events.partner_tank_death.connect(on_partner_tank_death)
	pass

static func start_level() -> void:
	current_level_buff_map.clear()
	enemy_kill_counts.clear()
	pass


## buff_map 中己方坦克 id，按 key 升序
static func get_player_tank_ids() -> Array[int]:
	var tank_ids: Array[int] = []
	for tank_id: int in buff_map:
		var tank_config := TankConfig.tank_datas[tank_id]
		if TankConfig.is_enemy_faction(tank_config.team):
			continue
		tank_ids.append(tank_id)
	tank_ids.sort()
	return tank_ids

static func remove_current_level_buffs() -> void:
	for id: int in current_level_buff_map:
		if !buff_map.has(id):
			continue
		var buff_container := buff_map[id]
		var level_buff_container := current_level_buff_map[id]
		for buff: IBuff in level_buff_container.buffs:
			buff_container.remove_buff(buff)
	current_level_buff_map.clear()
	pass

static func get_buff_container(id: int) -> BuffContainer:
	if !buff_map.has(id):
		buff_map[id] = BuffContainer.new()
	var buff_container := buff_map[id]
	return buff_container

static func add_current_level_buff(id: int, buff: IBuff) -> void:
	if !current_level_buff_map.has(id):
		current_level_buff_map[id] = BuffContainer.new()
	current_level_buff_map[id].add_buff(buff)
	pass

static func can_add_buff(tank: Tank, buff_type: int) -> bool:
	var buff_data := BuffConfig.buff_datas[buff_type]
	var buff_container := get_buff_container(tank.id)
	var buff_type_of_size := buff_container.buff_type_of_size(buff_type)
	if buff_data.max_stack >= 0 and buff_type_of_size >= buff_data.max_stack:
		return false
	return true

static func add_buff(tank: Tank, buff_type: int) -> bool:
	if !can_add_buff(tank, buff_type):
		return false
	var buff_data := BuffConfig.buff_datas[buff_type]
	var buff_container := get_buff_container(tank.id)
	var buff: IBuff = buff_data.buff.new_buff()
	if buff_data.max_stack > 0:
		buff_container.add_buff(buff)
		add_current_level_buff(tank.id, buff)
		update_tank_appearance(tank, buff_container.buffs)
	buff.trigger(tank)
	return true


# ----------------------------------------------------------------------------------------------------------------------

static func wrap_buff_container(tank: Tank) -> void:
	var id := tank.id
	if !buff_map.has(id):
		return
	var buff_container := buff_map[id]
	trigger_buffs(tank, buff_container.buffs)
	pass

static func trigger_buffs(tank: Tank, buffs: Array[IBuff]) -> void:
	for buff in buffs:
		buff.trigger(tank)
	update_tank_appearance(tank, buffs)
	pass

# ----------------------------------------------------------------------------------------------------------------------


static func update_tank_appearance(tank: Tank, buffs: Array[IBuff]) -> void:
	if tank.team == TankConfig.Team.BOSS_ENEMY:
		return
	var buff_container := get_buff_container(tank.id)
	var bullet_buff_count := buff_container.buff_type_of_size(IBuff.BuffType.BULLET_SPEED)
	bullet_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.BULLET_SIZE)
	bullet_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.BULLET_FIRE_INTERVAL)
	
	var tank_buff_count := buff_container.buff_type_of_size(IBuff.BuffType.TANK_SPEED)
	tank_buff_count = tank_buff_count + buff_container.buff_type_of_size(IBuff.BuffType.TANK_SIZE)
	tank_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.TANK_RESPAWN)
	tank_buff_count += buff_container.buff_type_of_size(IBuff.BuffType.TANK_HP)
	
	var bullet_resource_before: String = StringUtils.substring_before_last(tank.bullet_resource, "/")
	var tank_resource_before: String = StringUtils.substring_before_last(tank.tank_resource, "_")
	
	var bullet_id := clampi(bullet_buff_count, 1, 6)
	var tank_id := clampi(tank_buff_count, 1, 6)
	
	var bullet_resource := StringUtils.format("{}/{}.png", bullet_resource_before, bullet_id)
	var tank_resource := StringUtils.format("{}_{}.png", tank_resource_before, tank_id)
	tank.bullet_resource = bullet_resource
	tank.tank_resource = tank_resource
	tank.scale_tank_deferred()
	pass

# ----------------------------------------------------------------------------------------------------------------------

static func on_enemy_tank_death(tank: Tank) -> void:
	var id := tank.id
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[id]
	if tank_config.team == TankConfig.Team.PLAYER:
		return
	var killer_id := tank.killed_by_tank_id
	if killer_id >= 0 and TankConfig.tank_datas.has(killer_id):
		enemy_kill_counts[killer_id] = enemy_kill_counts.get(killer_id, 0) + 1
	var grid_pos := tank.grid_pos
	if tank.team == TankConfig.Team.ELITE_ENEMY:
		gdf.callable_deferred(func() -> void: BuffHelper.create_buff(BuffConfig.random_buff(), grid_pos))
	if tank.team == TankConfig.Team.BOSS_ENEMY:
		gdf.callable_deferred(func() -> void: BuffHelper.create_buff(BuffConfig.random_enhance_buff(), grid_pos))
		gdf.callable_deferred(func() -> void: BuffHelper.create_buff(BuffConfig.random_enhance_buff(), grid_pos + Vector2i.ONE * 2))
	pass

# ----------------------------------------------------------------------------------------------------------------------

static func on_player_tank_death(tank: Tank) -> void:
	var tank_config: TankConfig.TankData = TankConfig.tank_datas[tank.id]
	var buff_container := get_buff_container(tank.id)
	buff_container.remove_buff_by_type(IBuff.BuffType.TANK_SIZE)
	
	var buff_type_of_size := buff_container.buff_type_of_size(IBuff.BuffType.TANK_RESPAWN)
	var respawn_time := DEFAULT_RESPAWN_TIME - buff_type_of_size * TankRespawnBuff.EFFECT_VALUE
	var parent := tank.get_parent()
	RespawnCountdown.spawn(tank.global_position, respawn_time, parent)
	parent.create_tween().tween_callback(on_respawn.bind(tank_config)).set_delay(respawn_time)
	pass

static func on_partner_tank_death(tank: Tank) -> void:
	on_player_tank_death(tank)
	pass

static func on_respawn(tank_config: TankConfig.TankData) -> void:
	if BattleProgress.level_ended:
		return
	if tank_config.team == TankConfig.Team.PLAYER:
		TankHelper.create_tank(tank_config, Eagle.player_tank_start_grid_pos)
	else:
		TankHelper.create_tank(tank_config, Eagle.partner_tank_start_grid_pos)
	Audios.play_sfx(AudioConfig.TANK_RELOAD)
	pass

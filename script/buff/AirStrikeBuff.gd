class_name AirStrikeBuff
extends IBuff

const AIRCRAFT_TEXTURE := "res://image/buff/air_strike.png"
const AIRCRAFT_SHADER := "res://shader/aircraft_flight.gdshader"
const FLIGHT_DURATION := 3.0
const AIRCRAFT_INTERVAL := 0.4
const AIRCRAFT_WIDTH_RATIO := 0.22
const ENEMY_EXPLOSION_INTERVAL := 0.25


func trigger(tank: Tank) -> void:
	if tank.is_enemy():
		return

	var texture: Texture2D = load(AIRCRAFT_TEXTURE)
	var shader: Shader = load(AIRCRAFT_SHADER)
	var map_width := TileConfig.MAP_GRID_WIDTH * TileConfig.TILE_SIZE
	var map_height := TileConfig.MAP_GRID_HEIGHT * TileConfig.TILE_SIZE
	var aircraft_scale := map_width * AIRCRAFT_WIDTH_RATIO / texture.get_size().x
	var half_width := texture.get_size().x * aircraft_scale * 0.5
	var half_height := texture.get_size().y * aircraft_scale * 0.5
	var lane_xs := build_lane_xs(half_width, map_width - half_width, half_width * 2.0)

	var count := randi_range(5, 9)
	for i in count:
		Audios.play_sfx(AudioConfig.BUFF_AIR_STRIKE)
		var aircraft := Sprite2D.new()
		aircraft.texture = texture
		aircraft.scale = Vector2.ONE * aircraft_scale
		aircraft.z_index = 512

		var flight_material := ShaderMaterial.new()
		flight_material.shader = shader
		flight_material.set_shader_parameter("phase_offset", randf_range(0.0, TAU))
		flight_material.set_shader_parameter("world_scale", aircraft_scale)
		aircraft.material = flight_material

		tank.get_parent().add_child(aircraft)

		var aircraft_x: float = lane_xs[i % lane_xs.size()]
		var start_pos := Vector2(aircraft_x, map_height + half_height)
		var end_pos := Vector2(aircraft_x, -half_height)
		aircraft.global_position = start_pos
		
		var tween := aircraft.create_tween()
		var delay := i * AIRCRAFT_INTERVAL
		tween.tween_property(aircraft, "global_position", end_pos, FLIGHT_DURATION).set_delay(delay)
		tween.tween_callback(func() -> void: aircraft.queue_free())

	var kill_tween := tank.get_parent().create_tween()
	kill_tween.tween_interval(FLIGHT_DURATION)
	kill_tween.tween_callback(kill_all)
	pass

static func kill_all() -> void:
	var enemies: Array[Tank] = []
	for target in TankHelper.tanks:
		if is_instance_valid(target) and target.is_alive_enemy():
			enemies.append(target)
	if enemies.is_empty():
		return

	enemies.sort_custom(func(a: Tank, b: Tank) -> bool: return a.global_position.y > b.global_position.y)
	for i in enemies.size():
		var enemy := enemies[i]
		var explosion_tween := enemy.create_tween()
		explosion_tween.tween_interval(i * ENEMY_EXPLOSION_INTERVAL)
		explosion_tween.tween_callback(func() -> void:
			if !is_instance_valid(enemy):
				return
			var damage: int = enemy.hp
			match enemy.team:
				TankConfig.Team.ELITE_ENEMY:
					damage = maxi(damage * 0.5 as int, 5)
				TankConfig.Team.BOSS_ENEMY:
					damage = maxi(damage * 0.2 as int, 5)
			EffectAnimation2D.spawn(
				enemy.global_position,
				enemy.get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_STEEL,
				Vector2i(6, 3))
			enemy.take_damage(damage)
		)
	pass

func build_lane_xs(min_x: float, max_x: float, aircraft_width: float) -> Array[float]:
	var available := maxf(max_x - min_x, 0.0)
	var lane_count := maxi(1, int(available / aircraft_width) + 1)
	var xs: Array[float] = []
	for i in lane_count:
		var t := 0.0 if lane_count == 1 else float(i) / float(lane_count - 1)
		xs.append(lerpf(min_x, max_x, t))
	xs.shuffle()
	return xs

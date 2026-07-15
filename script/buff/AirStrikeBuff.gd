class_name AirStrikeBuff
extends Buff

const AIRCRAFT_TEXTURE := "res://image/buff/air_strike.png"
const FLIGHT_DURATION := 3.0


func trigger(tank: Tank) -> void:
	if tank.team != TankConfig.Team.PLAYER:
		return

	var texture: Texture2D = load(AIRCRAFT_TEXTURE)
	var map_width := TileConfig.MAP_GRID_WIDTH * TileConfig.TILE_SIZE
	var map_height := TileConfig.MAP_GRID_HEIGHT * TileConfig.TILE_SIZE
	var aircraft_scale := map_width * 0.75 / texture.get_size().x
	var half_height := texture.get_size().y * aircraft_scale * 0.5

	var aircraft := Sprite2D.new()
	aircraft.texture = texture
	aircraft.scale = Vector2.ONE * aircraft_scale
	aircraft.z_index = 100
	aircraft.global_position = Vector2(map_width * 0.5, map_height + half_height)
	tank.get_parent().add_child(aircraft)
	
	Audios.play_sfx(AudioConfig.BUFF_AIR_STRIKE)

	var tween := tank.get_parent().create_tween()
	tween.tween_property(aircraft, "global_position", Vector2(map_width * 0.5, -half_height), FLIGHT_DURATION)
	tween.finished.connect(func() -> void:
		for target in TankHelper.tanks.duplicate():
			if is_instance_valid(target) and target.team == TankConfig.Team.ENEMY and target.is_alive():
				target.take_damage(target.hp)
		aircraft.queue_free()
	)

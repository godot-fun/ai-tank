extends Tank
class_name Enemy

func play_enter_animation() -> void:
	visible = false
	moving = true
	update_facing(Vector2i.DOWN)

	var target_pos := global_position
	global_position = Vector2(
		target_pos.x,
		-grid_size.y * TileConfig.TILE_SIZE * 0.5 - TileConfig.TILE_SIZE,
	)
	visible = true

	var duration := global_position.distance_to(target_pos) / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	tween.finished.connect(func() -> void:
		moving = false
		global_position = TileConfig.grid_to_world(grid_pos, grid_size)
	)
	pass

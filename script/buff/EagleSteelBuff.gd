class_name EagleSteelBuff
extends IBuff

const EFFECT_DURATION := 15.0


func trigger(tank: Tank) -> void:
	var tween := tank.get_parent().create_tween()
	tween.tween_callback(fortify_eagle)
	tween.tween_interval(EFFECT_DURATION)
	tween.tween_callback(restore_eagle)
	pass


func type() -> BuffType:
	return BuffType.EAGLE_STEEL


static func fortify_eagle() -> void:
	for grid in Eagle.base_wall_grids():
		TileHelper.replace_tile(TileConfig.steel_wall, grid)
	pass


static func restore_eagle() -> void:
	for grid in Eagle.base_wall_grids():
		TileHelper.replace_tile(TileConfig.brick_wall_eagle, grid)
	pass

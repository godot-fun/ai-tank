class_name BaseSteelBuff
extends IBuff

const EFFECT_DURATION := 15.0


func trigger(tank: Tank) -> void:
	var tween := tank.get_parent().create_tween()
	tween.tween_callback(fortify_base)
	tween.tween_interval(EFFECT_DURATION)
	tween.tween_callback(restore_base)
	pass


func type() -> BuffType:
	return BuffType.BASE_STEEL


static func fortify_base() -> void:
	for grid in Eagle.base_wall_grids():
		TileHelper.replace_tile(TileConfig.steel_wall, grid)
	pass


static func restore_base() -> void:
	for grid in Eagle.base_wall_grids():
		TileHelper.replace_tile(TileConfig.brick_wall_eagle, grid)
	pass

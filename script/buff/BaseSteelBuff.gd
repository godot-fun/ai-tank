class_name BaseSteelBuff
extends IBuff

const EFFECT_DURATION_MS := 15 * TimeUtils.MILLIS_PER_SECOND


func trigger(_tank: Tank) -> void:
	# body_entered 处于物理查询刷新中，不能立刻增删 StaticBody2D
	gdf.callable_deferred(fortify_base)
	SchedulerBus.schedule(restore_base, EFFECT_DURATION_MS)
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

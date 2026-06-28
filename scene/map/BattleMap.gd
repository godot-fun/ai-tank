extends Node2D

@export var show_grid: bool = false

var _watching_clear := false


func _ready() -> void:
	z_index = -10
	regenerate_map()
	pass


func _process(_delta: float) -> void:
	if not _watching_clear:
		return
	if TankHelper.get_alive_enemy_count() > 0:
		return
	_watching_clear = false
	on_level_cleared()
	pass


func regenerate_map() -> void:
	clear_battlefield()
	MapGeneratorHelper.build(self, BattleProgress.level, BattleProgress.get_enemy_count())
	_watching_clear = BattleProgress.get_enemy_count() > 0
	queue_redraw()
	pass


func clear_battlefield() -> void:
	TileHelper.clear_grid()
	for child in get_children():
		SceneHelper.queue_free(child)
	pass


func on_level_cleared() -> void:
	Audio.play_sound("res://audio/sfx/level-clear/01.wav")
	BattleProgress.next_level()
	await ThreadUtils.async_sleep(1500)
	regenerate_map()
	pass


func _draw() -> void:
	if not show_grid:
		return

	var tile_size := TankConfig.tile_size
	var map_width := TankConfig.map_grid_width * tile_size
	var map_height := TankConfig.map_grid_height * tile_size
	var grid_color := Color(1.0, 1.0, 1.0, 0.25)

	for x in range(TankConfig.map_grid_width + 1):
		var px := x * tile_size
		draw_line(Vector2(px, 0.0), Vector2(px, map_height), grid_color)

	for y in range(TankConfig.map_grid_height + 1):
		var py := y * tile_size
		draw_line(Vector2(0.0, py), Vector2(map_width, py), grid_color)
	pass

extends Node2D

@export var show_grid: bool = false


func _ready() -> void:
	Log.info("map size:[{} * {}]", TileConfig.MAP_GRID_WIDTH, TileConfig.MAP_GRID_HEIGHT)
	z_index = -10
	queue_redraw()
	pass


func _draw() -> void:
	if not show_grid:
		return

	var tile_size := TileConfig.TILE_SIZE
	var map_width := TileConfig.MAP_GRID_WIDTH * tile_size
	var map_height := TileConfig.MAP_GRID_HEIGHT * tile_size
	var grid_color := Color(1.0, 1.0, 1.0, 0.25)

	for x in range(TileConfig.MAP_GRID_WIDTH + 1):
		var px := x * tile_size
		draw_line(Vector2(px, 0.0), Vector2(px, map_height), grid_color)

	for y in range(TileConfig.MAP_GRID_HEIGHT + 1):
		var py := y * tile_size
		draw_line(Vector2(0.0, py), Vector2(map_width, py), grid_color)
	pass

extends Node2D

@export var show_grid: bool = false


func _ready() -> void:
	z_index = -10
	queue_redraw()
	EagleHelper.create_eagle()
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

extends Node2D

## 随机加载一张关卡地图，随机起终点，调用 PathFinderHelper 寻路并绘制路径。
## 空格 / R：重新随机关卡与起终点。

const TANK_GRID_SIZE := Vector2i(2, 2)
## 起终点曼哈顿距离下限（约半张图），不足则取最远可走格
const MIN_START_GOAL_DIST := 20

var level_index := 0
var start_grid := Vector2i.ZERO
var goal_grid := Vector2i.ZERO
var path: Array[Vector2i] = []
var info_label: Label


func _ready() -> void:
	setup_hud()
	reroll()
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_R:
			reroll()
	pass


func _draw() -> void:
	draw_footprint(start_grid, Color(0.2, 0.9, 0.35, 0.45), Color(0.15, 0.85, 0.3, 1.0))
	draw_footprint(goal_grid, Color(0.95, 0.25, 0.25, 0.45), Color(0.95, 0.2, 0.2, 1.0))

	if path.size() < 2:
		return

	var points: PackedVector2Array = []
	for cell in path:
		points.append(TileConfig.grid_to_world(cell, TANK_GRID_SIZE))

	draw_polyline(points, Color(0.15, 0.85, 1.0, 0.95), 6.0, true)
	for i in points.size():
		var radius := 10.0 if i > 0 and i < points.size() - 1 else 14.0
		draw_circle(points[i], radius, Color(1.0, 0.9, 0.2, 0.95))
	pass


func reroll() -> void:
	level_index = randi() % LevelConfig.MAP_DATA.size()
	LevelConfig.load_level(level_index)

	var walkable := collect_walkable_cells()
	if walkable.size() < 2:
		path.clear()
		Log.error("level [{}] walkable cells < 2", level_index)
		refresh_label()
		queue_redraw()
		return

	start_grid = RandomUtils.random_ele(walkable)
	goal_grid = pick_far_goal(walkable, start_grid)

	path = PathFinderHelper.find_path(start_grid, goal_grid, TANK_GRID_SIZE)
	Log.info(
		"pathfinder level:[{}] start:{} goal:{} path_len:[{}]",
		level_index + 1,
		start_grid,
		goal_grid,
		path.size(),
	)
	refresh_label()
	queue_redraw()
	pass


func collect_walkable_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var max_x := TileConfig.MAP_GRID_WIDTH - TANK_GRID_SIZE.x
	var max_y := TileConfig.MAP_GRID_HEIGHT - TANK_GRID_SIZE.y
	for x in range(max_x + 1):
		for y in range(max_y + 1):
			var cell := Vector2i(x, y)
			if TileHelper.is_area_blocked_for_tank(cell, TANK_GRID_SIZE):
				continue
			result.append(cell)
	return result


func pick_far_goal(walkable: Array[Vector2i], from: Vector2i) -> Vector2i:
	var far_cells: Array[Vector2i] = []
	var farthest := from
	var farthest_dist := -1
	for cell in walkable:
		var dist := absi(cell.x - from.x) + absi(cell.y - from.y)
		if dist > farthest_dist:
			farthest_dist = dist
			farthest = cell
		if dist >= MIN_START_GOAL_DIST:
			far_cells.append(cell)
	if far_cells.is_empty():
		return farthest
	return RandomUtils.random_ele(far_cells)


func draw_footprint(grid: Vector2i, fill: Color, outline: Color) -> void:
	var rect := Rect2(
		Vector2(grid) * TileConfig.TILE_SIZE,
		Vector2(TANK_GRID_SIZE) * TileConfig.TILE_SIZE,
	)
	draw_rect(rect, fill, true)
	draw_rect(rect, outline, false, 3.0)
	pass


func setup_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 28)
	info_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	info_label.position = Vector2(24, 16)
	hud_layer.add_child(info_label)
	pass


func refresh_label() -> void:
	info_label.text = "关卡 %d | 起点 %s → 终点 %s | 路径 %d 格 | 空格/R 重随" % [
		level_index + 1,
		str(start_grid),
		str(goal_grid),
		path.size(),
	]
	pass

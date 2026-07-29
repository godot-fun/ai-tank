extends Tank
class_name PartnerTank

const BUFF_SEEK_RANGE := 5
const FORWARD_DETECT_RADIUS := TileConfig.TILE_SIZE * 0.35

var forward_shape_cast: ShapeCast2D


func start() -> void:
	facing = Vector2i.UP
	update_facing(facing)
	ensure_forward_shape_cast()
	pass


## 选取朝向目标格的方向：优先 buff，其次最近敌人，再次跟随玩家。
func pick_partner_target_grid() -> Vector2i:
	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE)
	if nearby_buff != null:
		return nearby_buff.grid_pos

	var enemy := TankHelper.find_nearest_enemy(self)
	if enemy != null:
		return enemy.grid_pos

	var leader := TankHelper.find_player()
	if leader != null and leader != self:
		return leader.grid_pos

	return Vector2i.ZERO


func fire() -> void:
	if would_hit_home():
		return
	super.fire()


## 开火会打到基地（直面基地、基地前无挡子弹地块、基地前无敌方坦克）。
func would_hit_home() -> bool:
	return is_facing_home() and not has_blocking_tile_in_facing() and not has_enemy_in_facing()


## 是否直面基地。
func is_facing_home() -> bool:
	var home := Eagle.egale_first_grid_pos
	var home_max := home + Vector2i.ONE
	var self_max := grid_pos + grid_size - Vector2i.ONE
	var x_overlap := grid_pos.x <= home_max.x and self_max.x >= home.x
	var y_overlap := grid_pos.y <= home_max.y and self_max.y >= home.y

	match facing:
		Vector2i.LEFT:
			return grid_pos.x > home_max.x and y_overlap
		Vector2i.RIGHT:
			return self_max.x < home.x and y_overlap
		Vector2i.UP:
			return grid_pos.y > home_max.y and x_overlap
		Vector2i.DOWN:
			return self_max.y < home.y and x_overlap
	return false


## 朝向上是否有可阻挡子弹的地块。
## 先取朝向前沿，再一层一层向外推进。
## 同层碰到基地直接 false（旁侧墙不算挡在基地前）；整层扫完仍有阻挡才 true。
func has_blocking_tile_in_facing() -> bool:
	var home := Eagle.egale_first_grid_pos
	var home_max := home + Vector2i.ONE

	var layer: Array[Vector2i] = []
	match facing:
		Vector2i.LEFT:
			for oy in range(grid_size.y):
				layer.append(Vector2i(grid_pos.x - 1, grid_pos.y + oy))
		Vector2i.RIGHT:
			for oy in range(grid_size.y):
				layer.append(Vector2i(grid_pos.x + grid_size.x, grid_pos.y + oy))
		Vector2i.UP:
			for ox in range(grid_size.x):
				layer.append(Vector2i(grid_pos.x + ox, grid_pos.y - 1))
		Vector2i.DOWN:
			for ox in range(grid_size.x):
				layer.append(Vector2i(grid_pos.x + ox, grid_pos.y + grid_size.y))
		_:
			return false

	while not layer.is_empty():
		var next_layer: Array[Vector2i] = []
		var has_blocker := false

		for cell in layer:
			if not TileHelper.is_cell_in_bounds(cell):
				continue
			# 同层碰到基地（即便旁边还有墙）→ 无保护
			if cell.x >= home.x and cell.x <= home_max.x \
					and cell.y >= home.y and cell.y <= home_max.y:
				return false

			var tile := TileHelper.get_tile(cell)
			if tile != null and tile.blocks_bullet():
				has_blocker = true
				continue

			next_layer.append(cell + facing)

		if has_blocker:
			return true
		layer = next_layer

	return false


## 朝向上、且在基地之前是否有敌方坦克（可挡子弹；基地后的敌人不算）。
func has_enemy_in_facing() -> bool:
	var home := Eagle.egale_first_grid_pos
	var home_max := home + Vector2i.ONE
	var self_max := grid_pos + grid_size - Vector2i.ONE

	for tank in TankHelper.tanks:
		if not tank.is_alive_enemy():
			continue
		var t_min := tank.grid_pos
		var t_max := tank.grid_pos + tank.grid_size - Vector2i.ONE
		match facing:
			Vector2i.LEFT:
				if t_max.x < grid_pos.x and t_min.x > home_max.x \
						and t_min.y <= self_max.y and t_max.y >= grid_pos.y:
					return true
			Vector2i.RIGHT:
				if t_min.x > self_max.x and t_max.x < home.x \
						and t_min.y <= self_max.y and t_max.y >= grid_pos.y:
					return true
			Vector2i.UP:
				if t_max.y < grid_pos.y and t_min.y > home_max.y \
						and t_min.x <= self_max.x and t_max.x >= grid_pos.x:
					return true
			Vector2i.DOWN:
				if t_min.y > self_max.y and t_max.y < home.y \
						and t_min.x <= self_max.x and t_max.x >= grid_pos.x:
					return true
	return false


## 用 ShapeCast2D 检测坦克正前方第一个碰到的物体。
## 由于扫射有宽度，同层可能命中多个；这里按前向投影距离取最近一个。
func detect_first_object_in_front(max_distance: float = -1.0) -> Node2D:
	var cast_distance := max_distance
	if cast_distance <= 0.0:
		cast_distance = float(maxi(TileConfig.MAP_GRID_WIDTH, TileConfig.MAP_GRID_HEIGHT) * TileConfig.TILE_SIZE)

	var forward := Vector2(facing).normalized()
	var front_offset := Vector2(grid_size) * TileConfig.TILE_SIZE * 0.5
	forward_shape_cast.position = forward * (minf(front_offset.x, front_offset.y) + FORWARD_DETECT_RADIUS + 1.0)
	forward_shape_cast.target_position = forward * cast_distance
	forward_shape_cast.force_shapecast_update()

	var hit_count := forward_shape_cast.get_collision_count()
	if hit_count <= 0:
		return null

	var origin := forward_shape_cast.global_position
	var nearest_hit_distance := INF
	var nearest_collider: Node2D
	for index in range(hit_count):
		var collider := forward_shape_cast.get_collider(index)
		if collider == null or collider == self:
			continue
		if not collider is Node2D:
			continue

		var hit_point := forward_shape_cast.get_collision_point(index)
		var distance_on_forward := (hit_point - origin).dot(forward)
		if distance_on_forward < 0.0:
			continue
		if distance_on_forward < nearest_hit_distance:
			nearest_hit_distance = distance_on_forward
			nearest_collider = collider as Node2D
	return nearest_collider


func ensure_forward_shape_cast() -> void:
	if forward_shape_cast != null:
		return

	forward_shape_cast = ShapeCast2D.new()
	forward_shape_cast.enabled = true
	forward_shape_cast.exclude_parent = true
	forward_shape_cast.collide_with_areas = true
	forward_shape_cast.collide_with_bodies = true

	var shape := CircleShape2D.new()
	shape.radius = FORWARD_DETECT_RADIUS
	forward_shape_cast.shape = shape

	add_child(forward_shape_cast)
	pass

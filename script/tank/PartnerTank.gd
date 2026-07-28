extends Tank
class_name PartnerTank

const AI_THINK_INTERVAL := 0.5
const RANDOM_MOVE_EXTRA_STEPS_MAX := 2
const BUFF_SEEK_RANGE := 5


var ai_think_timer := 0.0


func start() -> void:
	facing = Vector2i.UP
	update_facing(facing)
	ai_think_timer = AI_THINK_INTERVAL
	pass


func physics_update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		var direction := pick_move_direction()
		if direction != Vector2i.ZERO:
			move(direction, RandomUtils.random_int_limit(RANDOM_MOVE_EXTRA_STEPS_MAX))
		fire()
	pass


func pick_move_direction() -> Vector2i:
	var target_grid := Vector2i.ZERO

	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE)
	if nearby_buff != null:
		target_grid = nearby_buff.grid_pos
	else:
		var enemy := TankHelper.find_nearest_enemy(self)
		if enemy != null:
			target_grid = enemy.grid_pos
		else:
			var leader := TankHelper.find_player()
			if leader != null and leader != self:
				target_grid = leader.grid_pos

	if target_grid == Vector2i.ZERO:
		return Vector2i.ZERO

	return pick_direction_toward(target_grid)


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

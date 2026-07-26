extends PartnerTank
class_name PartnerSmartTank

## 更大范围找 buff；A* 一次后沿直线连走多步，减少重算。
const BUFF_SEEK_RANGE_SMART := 28

var pending_steps := 1


func physics_update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		pending_steps = 1
		var direction := pick_move_direction()
		if direction != Vector2i.ZERO:
			if pending_steps <= 1:
				move(direction)
			else:
				move(direction, pending_steps - 1)
		fire()
	pass


func pick_move_direction() -> Vector2i:
	var target_grid := Vector2i.ZERO

	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE_SMART)
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

	return go_to(target_grid)


## 传入目标格子：A* 算整条路径，沿首段直线连续走完再转弯。无路则不动（不贪心挤窄缝）。
func go_to(target_grid: Vector2i) -> Vector2i:
	var path := PathFinderHelper.find_path(grid_pos, target_grid, grid_size, self)
	if path.size() < 2:
		return Vector2i.ZERO

	var direction := path[1] - path[0]
	if absi(direction.x) + absi(direction.y) != 1:
		return Vector2i.ZERO
	if TankHelper.is_move_blocked(path[1], grid_size, self):
		return Vector2i.ZERO

	pending_steps = 1
	while pending_steps + 1 < path.size():
		var next_cell := path[pending_steps + 1]
		if next_cell - path[pending_steps] != direction:
			break
		if TankHelper.is_move_blocked(next_cell, grid_size, self):
			break
		pending_steps += 1

	return direction

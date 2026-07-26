extends PartnerTank
class_name PartnerSmartTank

## 使用 AStarGrid2D 格子寻路跟随目标，替代 PartnerTank 的贪心朝向。
const BUFF_SEEK_RANGE_SMART := 28
const MAX_STRAIGHT_STEPS := 4

var path: Array[Vector2i] = []
var path_index := 0
var path_target := Vector2i.ZERO
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
	var target_grid := resolve_target_grid()
	if target_grid == Vector2i.ZERO:
		clear_path()
		return Vector2i.ZERO

	if not ensure_path(target_grid):
		return pick_direction_toward(target_grid)

	var next_cell := path[path_index]
	var direction := next_cell - grid_pos
	if absi(direction.x) + absi(direction.y) != 1:
		clear_path()
		return pick_direction_toward(target_grid)

	if TankHelper.is_move_blocked(next_cell, grid_size, self):
		clear_path()
		return pick_random_not_blocked_direction()

	pending_steps = count_straight_steps(direction)
	path_index += pending_steps
	return direction


func resolve_target_grid() -> Vector2i:
	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE_SMART)
	if nearby_buff != null:
		return nearby_buff.grid_pos

	var enemy := TankHelper.find_nearest_enemy(self)
	if enemy != null:
		return enemy.grid_pos

	var leader := TankHelper.find_player()
	if leader != null and leader != self:
		return leader.grid_pos

	return Vector2i.ZERO


func ensure_path(target_grid: Vector2i) -> bool:
	if path.is_empty() or path_target != target_grid:
		rebuild_path(target_grid)
	elif path_index > 0 and path[path_index - 1] != grid_pos:
		var found := path.find(grid_pos)
		if found >= 0:
			path_index = found + 1
		else:
			rebuild_path(target_grid)

	return path_index < path.size()


func rebuild_path(target_grid: Vector2i) -> void:
	path = PathFinderHelper.find_path(grid_pos, target_grid, grid_size, self)
	path_target = target_grid
	path_index = 0
	if not path.is_empty() and path[0] == grid_pos:
		path_index = 1
	pass


func clear_path() -> void:
	path.clear()
	path_index = 0
	path_target = Vector2i.ZERO
	pass


func count_straight_steps(direction: Vector2i) -> int:
	var steps := 1
	var cursor := path_index
	while steps < MAX_STRAIGHT_STEPS and cursor + 1 < path.size():
		var step_dir := path[cursor + 1] - path[cursor]
		if step_dir != direction:
			break
		if TankHelper.is_move_blocked(path[cursor + 1], grid_size, self):
			break
		steps += 1
		cursor += 1
	return steps

extends PartnerTank
class_name PartnerSmartTank

## 更大范围找 buff；A* 一次后沿直线连走多步，减少重算。
const BUFF_SEEK_RANGE_SMART := 28
const AI_THINK_INTERVAL := 0.5
const RANDOM_MOVE_EXTRA_STEPS_MAX := 2

var ai_think_timer := 0.0
var pending_steps := 1


func physics_update(delta: float) -> void:
	ai_think_timer -= delta

	if fire_on_enemy():
		return

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
		else:
			# A* 无路或下一步被挡时随机走动，避免站桩只打砖墙。
			move(pick_random_not_blocked_direction(), RandomUtils.random_int_limit(RANDOM_MOVE_EXTRA_STEPS_MAX))
		fire()
	pass


## 见敌开火：四向任一能直接打到敌人则转向并原地开火。成功则返回 true。
func fire_on_enemy() -> bool:
	if not can_fire():
		return false
	var fire_dir := find_direct_fire_direction()
	if fire_dir == Vector2i.ZERO:
		return false
	update_facing(fire_dir)
	fire()
	return true


func fire() -> void:
	if !can_fire():
		return
	var detect_objects := ray_detect_nearest_objects_in_front(4)
	for obj in detect_objects:
		if obj is Eagle:
			return
	for obj in detect_objects:
		if obj is Enemy:
			super.fire()
			return
	for obj in detect_objects:
		if obj is BrickWallEagle:
			return
	if detect_objects.all(func(it) -> bool: return it is BrickWall):
		super.fire()
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

	if target_grid == Vector2i.ZERO:
		return Vector2i.ZERO

	return go_to(target_grid)


## 传入目标格子：A* 算整条路径，沿首段直线连续走完再转弯。无路则不动（不贪心挤窄缝）。
func go_to(target_grid: Vector2i) -> Vector2i:
	var path := PathFinderHelper.find_path(grid_pos, target_grid, grid_size)
	if path.size() < 2:
		return Vector2i.ZERO

	var direction := path[1] - path[0]
	if absi(direction.x) + absi(direction.y) != 1:
		return Vector2i.ZERO

	pending_steps = 1
	while pending_steps + 1 < path.size():
		var next_cell := path[pending_steps + 1]
		if next_cell - path[pending_steps] != direction:
			break
		pending_steps += 1

	return direction

## 上下左右任一方向能直接打到敌人则返回该方向；会误伤基地则跳过。
func find_direct_fire_direction() -> Vector2i:
	directions.shuffle()
	for dir in directions:
		var detect_objects := ray_detect_nearest_objects_toward(dir, 4)
		for obj in detect_objects:
			if obj is Enemy:
				return dir
			if obj is BasicBullet:
				var bullet := obj as BasicBullet
				if TankConfig.is_enemy_faction(bullet.team):
					return dir
	return Vector2i.ZERO
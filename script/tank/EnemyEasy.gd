extends Tank
class_name EnemyEasy

const AI_THINK_INTERVAL := 0.6

var ai_think_timer := 0.0


func start() -> void:
	apply_data(TankConfig.enemy_easy)
	facing = Vector2i(0, 1)
	update_facing(facing)
	ai_think_timer = AI_THINK_INTERVAL
	pass


func update(delta: float) -> void:
	ai_think_timer -= delta

	try_shoot_at_player()

	if moving:
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		var direction := pick_move_direction()
		if direction != Vector2i.ZERO:
			try_move(direction)
	pass


func pick_move_direction() -> Vector2i:
	var player := find_player()
	if player == null or randf() < 0.35:
		return pick_random_direction()

	return pick_direction_toward(get_tank_grid(player))
	pass


func pick_random_direction() -> Vector2i:
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
	]
	directions.shuffle()

	for direction in directions:
		var target_grid := grid_pos + direction
		if TankConfig.is_in_bounds(target_grid, grid_size) \
				and not TileHelper.is_area_blocked_for_tank(target_grid, grid_size):
			return direction

	return Vector2i.ZERO


func pick_direction_toward(target_grid: Vector2i) -> Vector2i:
	var diff := target_grid - grid_pos
	if diff == Vector2i.ZERO:
		return pick_random_direction()

	var candidates: Array[Vector2i] = []
	if diff.x != 0:
		candidates.append(Vector2i(signi(diff.x), 0))
	if diff.y != 0:
		candidates.append(Vector2i(0, signi(diff.y)))

	candidates.shuffle()
	for direction in candidates:
		if TankConfig.is_in_bounds(grid_pos + direction, grid_size):
			return direction

	return Vector2i.ZERO


func try_shoot_at_player() -> void:
	if not can_fire():
		return

	var player := find_player()
	if player == null:
		return

	var player_grid := get_tank_grid(player)
	var diff := player_grid - grid_pos
	if diff.x != 0 and diff.y != 0:
		return

	if diff.x != 0:
		update_facing(Vector2i(signi(diff.x), 0))
	else:
		update_facing(Vector2i(0, signi(diff.y)))

	try_shoot()
	pass


func find_player() -> Tank:
	for node in get_tree().current_scene.get_children():
		if node is Tank and node.team == TankConfig.Team.PLAYER:
			return node
	return null


func get_tank_grid(tank: Tank) -> Vector2i:
	return TankConfig.world_to_grid(tank.global_position, tank.grid_size)

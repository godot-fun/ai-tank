extends Tank
class_name EnemyEasy

const AI_THINK_INTERVAL := 0.6
const RANDOM_MOVE_EXTRA_STEPS_MIN := 1
const RANDOM_MOVE_EXTRA_STEPS_MAX := 6

var ai_think_timer := 0.0
var ai_move_extra_steps := 0


func start() -> void:
	apply_data(TankConfig.enemy_easy)
	update_facing(Vector2i.DOWN)
	ai_think_timer = AI_THINK_INTERVAL
	pass


func update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		var direction := pick_move_direction()
		if direction != Vector2i.ZERO:
			if ai_move_extra_steps > 0:
				move(direction, ai_move_extra_steps)
			else:
				move(direction)
	pass


func pick_move_direction() -> Vector2i:
	var player := TankHelper.find_player()
	if player == null or randf() < 0.35:
		ai_move_extra_steps = randi_range(RANDOM_MOVE_EXTRA_STEPS_MIN, RANDOM_MOVE_EXTRA_STEPS_MAX)
		return pick_random_direction()

	ai_move_extra_steps = 0
	return pick_direction_toward(TankHelper.get_tank_grid(player))
	pass


func pick_random_direction() -> Vector2i:
	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT,
	]
	directions.shuffle()

	for direction in directions:
		var target_grid := grid_pos + direction
		if not TankHelper.is_move_blocked(target_grid, grid_size, self):
			return direction

	return Vector2i.ZERO


func pick_direction_toward(target_grid: Vector2i) -> Vector2i:
	var diff := target_grid - grid_pos
	if diff == Vector2i.ZERO:
		return pick_random_direction()

	var candidates: Array[Vector2i] = []
	if diff.x != 0:
		candidates.append(Vector2i.RIGHT if signi(diff.x) > 0 else Vector2i.LEFT)
	if diff.y != 0:
		candidates.append(Vector2i.DOWN if signi(diff.y) > 0 else Vector2i.UP)

	candidates.shuffle()
	for direction in candidates:
		if not TankHelper.is_move_blocked(grid_pos + direction, grid_size, self):
			return direction

	return Vector2i.ZERO

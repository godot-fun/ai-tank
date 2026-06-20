extends CharacterBody2D

const MOVE_DURATION := 0.12

var grid_pos := Vector2i.ZERO
var moving := false


func _ready() -> void:
	grid_pos = TankConfig.world_to_grid(global_position)
	global_position = TankConfig.grid_to_world(grid_pos)


func _physics_process(_delta: float) -> void:
	if moving:
		return

	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)


func read_direction() -> Vector2i:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		return Vector2i(0, -1)
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		return Vector2i(0, 1)
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func try_move(direction: Vector2i) -> void:
	var target_grid := grid_pos + direction
	if not TankConfig.is_in_bounds(target_grid):
		return

	grid_pos = target_grid
	moving = true

	var tween := create_tween()
	tween.tween_property(self, "global_position", TankConfig.grid_to_world(grid_pos), MOVE_DURATION)
	tween.finished.connect(on_move_finished)


func on_move_finished() -> void:
	moving = false
	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)

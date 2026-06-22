extends Tank
class_name MyTank


func start() -> void:
	apply_data(TankConfig.my_tank)
	pass


func update(_delta: float) -> void:
	if Input.is_action_pressed("ui_accept"):
		try_shoot()

	if moving:
		return

	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)
	pass


func read_direction() -> Vector2i:
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		return Vector2i.UP
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		return Vector2i.DOWN
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		return Vector2i.LEFT
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		return Vector2i.RIGHT
	return Vector2i.ZERO


func on_move_continue() -> void:
	var direction := read_direction()
	if direction != Vector2i.ZERO:
		try_move(direction)
	pass

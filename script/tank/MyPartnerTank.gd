extends PartnerTank
class_name MyPartnerTank

## 玩家控制的僚机：IJKL 移动，Space 开火。
## 继承 PartnerTank 的 fire() 保护，不会误伤基地。


func physics_update(_delta: float) -> void:
	if Input.is_key_pressed(KEY_SPACE):
		fire()

	if moving:
		return

	var direction := read_direction()
	if direction == Vector2i.ZERO:
		return

	if direction != facing:
		update_facing(direction)
		return

	move(direction)
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

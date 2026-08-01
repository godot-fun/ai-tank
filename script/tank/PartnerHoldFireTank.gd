extends PartnerSmartTank
class_name PartnerHoldFireTank

## 开局前 HOLD_FIRE_SECONDS 秒：只前往最佳向上射击点并站桩开火，不随机游荡；之后回退为普通智能队友。
const HOLD_FIRE_SECONDS := 30.0

var hold_fire_remain := HOLD_FIRE_SECONDS


func physics_update(delta: float) -> void:
	if hold_fire_remain > 0.0:
		hold_fire_remain -= delta
		hold_fire_update(delta)
		return
	super.physics_update(delta)
	pass


func hold_fire_update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if fire_on_enemy():
		return

	if ai_think_timer > 0.0:
		return

	ai_think_timer = AI_THINK_INTERVAL
	pending_steps = 1
	var direction := pick_hold_fire_direction()
	if direction != Vector2i.ZERO:
		if pending_steps <= 1:
			move(direction)
		else:
			move(direction, pending_steps - 1)
		fire()
		return

	# 已在最佳射击点或暂时无路：面向上方开火清砖，绝不随机乱跑。
	if facing != Vector2i.UP:
		update_facing(Vector2i.UP)
	fire()
	pass


func pick_hold_fire_direction() -> Vector2i:
	var target := BestFireGridStrategy.find_best_fire_grid(self)
	if target == Vector2i.MIN or target == grid_pos:
		return Vector2i.ZERO
	return go_to(target)

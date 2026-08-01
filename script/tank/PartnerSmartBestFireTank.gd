extends PartnerSmartTank
class_name PartnerSmartBestFireTank

## 关卡进行时间未超过时限的 BEST_FIRE_RATIO：只前往最佳向上射击点并站桩开火，不随机游荡；之后回退为普通智能队友。
## 期间若曼哈顿距离 ≤ BUFF_SEEK_RANGE_EARLY 内有可拾取 buff，仍优先去拿。
const BEST_FIRE_RATIO := 0.5
const BUFF_SEEK_RANGE_EARLY := 10


func physics_update(delta: float) -> void:
	if BattleProgress.level_elapsed < BattleProgress.get_time_limit() * BEST_FIRE_RATIO:
		best_fire_update(delta)
		return
	super.physics_update(delta)
	pass


func best_fire_update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if fire_on_enemy():
		return

	if ai_think_timer > 0.0:
		return

	ai_think_timer = AI_THINK_INTERVAL
	var direction := pick_best_fire_direction()
	if direction != Vector2i.ZERO:
		move(direction)
		fire()
		return

	# 已在最佳射击点或暂时无路：面向上方开火清砖，绝不随机乱跑。
	if facing != Vector2i.UP:
		update_facing(Vector2i.UP)
	fire()
	pass


func pick_best_fire_direction() -> Vector2i:
	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE_EARLY)
	if nearby_buff != null:
		return go_to(nearby_buff.grid_pos)

	var target := BestFireGridStrategy.find_best_fire_grid(self)
	if target == Vector2i.MIN or target == grid_pos:
		return Vector2i.ZERO
	return go_to(target)

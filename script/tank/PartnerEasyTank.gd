extends PartnerTank
class_name PartnerEasyTank

const AI_THINK_INTERVAL := 0.5
const RANDOM_MOVE_EXTRA_STEPS_MAX := 2

var ai_think_timer := 0.0


func start() -> void:
	super.start()
	ai_think_timer = AI_THINK_INTERVAL
	pass


func physics_update(delta: float) -> void:
	ai_think_timer -= delta

	if moving:
		fire()
		return

	if ai_think_timer <= 0.0:
		ai_think_timer = AI_THINK_INTERVAL
		var target_grid := pick_partner_target_grid()
		var direction := Vector2i.ZERO
		if target_grid != Vector2i.ZERO:
			direction = pick_direction_toward(target_grid)
		if direction != Vector2i.ZERO:
			move(direction, RandomUtils.random_int_limit(RANDOM_MOVE_EXTRA_STEPS_MAX))
		fire()
	pass


func fire() -> void:
	if is_facing_home():
		return
	super.fire()
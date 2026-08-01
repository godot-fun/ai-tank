class_name FreezeBuff
extends IBuff

const EFFECT_DURATION := 10
const POLL_INTERVAL := 0.2

static var poll_timer: Timer
static var remaining_time := 0.0


func trigger(tank: Tank) -> void:
	remaining_time += EFFECT_DURATION
	if poll_timer == null or not is_instance_valid(poll_timer):
		start_poll(tank)
	freeze_all_enemies()


func type() -> BuffType:
	return BuffType.FREEZE

func new_buff() -> IBuff:
	return FreezeBuff.new()


static func start_poll(tank: Tank) -> void:
	poll_timer = Timer.new()
	poll_timer.name = "FreezePollTimer"
	poll_timer.wait_time = POLL_INTERVAL
	poll_timer.autostart = true
	tank.get_parent().add_child(poll_timer)
	poll_timer.timeout.connect(on_poll)


static func on_poll() -> void:
	freeze_all_enemies()
	remaining_time -= POLL_INTERVAL
	if remaining_time <= 0.0:
		stop_poll()
		unfreeze_all_enemies()


static func stop_poll() -> void:
	if poll_timer != null and is_instance_valid(poll_timer):
		poll_timer.queue_free()
	poll_timer = null
	remaining_time = 0.0


static func freeze_all_enemies() -> void:
	for target in TankHelper.tanks:
		if is_instance_valid(target) and target.is_alive_enemy():
			target.set_physics_process(false)


static func unfreeze_all_enemies() -> void:
	for target in TankHelper.tanks:
		if is_instance_valid(target) and target.is_alive_enemy():
			target.set_physics_process(true)

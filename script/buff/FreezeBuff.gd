class_name FreezeBuff
extends IBuff

const EFFECT_DURATION := 10
const POLL_INTERVAL := 0.2

static var _poll_timer: Timer
static var _remaining_time := 0.0


func trigger(tank: Tank) -> void:
	_remaining_time += EFFECT_DURATION
	if _poll_timer == null or not is_instance_valid(_poll_timer):
		_start_poll(tank)
	_freeze_all_enemies()


static func _start_poll(tank: Tank) -> void:
	_poll_timer = Timer.new()
	_poll_timer.wait_time = POLL_INTERVAL
	_poll_timer.autostart = true
	tank.get_parent().add_child(_poll_timer)
	_poll_timer.timeout.connect(_on_poll)


static func _on_poll() -> void:
	_freeze_all_enemies()
	_remaining_time -= POLL_INTERVAL
	if _remaining_time <= 0.0:
		_stop_poll()
		_unfreeze_all_enemies()


static func _stop_poll() -> void:
	if _poll_timer != null and is_instance_valid(_poll_timer):
		_poll_timer.queue_free()
	_poll_timer = null
	_remaining_time = 0.0


static func _freeze_all_enemies() -> void:
	for target in TankHelper.tanks:
		if is_instance_valid(target) and target.is_alive_enemy():
			target.set_physics_process(false)


static func _unfreeze_all_enemies() -> void:
	for target in TankHelper.tanks:
		if is_instance_valid(target) and target.is_alive_enemy():
			target.set_physics_process(true)

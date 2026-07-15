class_name EventBus

static var events := Events.new()


class Events:
	signal enemy_tank_death(tank: Tank)

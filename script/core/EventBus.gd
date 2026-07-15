class_name EventBus

static var events := Events.new()


class Events:
	signal tank_death(tank: Tank)

class_name TankConfig

const tile_size: int = 60
const tank_grid_size := Vector2i(2, 2)

# 地图的格子的长宽
static var map_grid_width: int = ProjectSettings.get_setting("display/window/size/viewport_width") / tile_size
static var map_grid_height: int = ProjectSettings.get_setting("display/window/size/viewport_height") / tile_size


enum Team {
	PLAYER,
	ENEMY
}

class TankData:
	var id: int
	var team: int
	var hp: int
	var max_hp: int
	var speed: float
	var bullet_speed: float
	var bullet_damage: int
	var fire_interval: float
	var invincible: bool

	func _init(
		_id: int,
		_team: int,
		_hp: int,
		_max_hp: int,
		_speed: float,
		_bullet_speed: float,
		_bullet_damage: int,
		_fire_interval: float,
		_invincible: bool,
	):
		id = _id
		team = _team
		hp = _hp
		max_hp = _max_hp
		speed = _speed
		bullet_speed = _bullet_speed
		bullet_damage = _bullet_damage
		fire_interval = _fire_interval
		invincible = _invincible

static var my_tank: TankData = TankData.new(0, Team.PLAYER, 1, 1, 400.0, 800.0, 1, 1.5, true)

static func grid_to_world(grid: Vector2i) -> Vector2:
	return Vector2(
		(grid.x + tank_grid_size.x * 0.5) * tile_size,
		(grid.y + tank_grid_size.y * 0.5) * tile_size,
	)


static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / tile_size - tank_grid_size.x * 0.5),
		floori(world_pos.y / tile_size - tank_grid_size.y * 0.5),
	)


static func is_in_bounds(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.x + tank_grid_size.x <= map_grid_width \
		and grid.y >= 0 and grid.y + tank_grid_size.y <= map_grid_height


static func clamp_grid_to_bounds(grid: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(grid.x, 0, map_grid_width - tank_grid_size.x),
		clampi(grid.y, 0, map_grid_height - tank_grid_size.y),
	)

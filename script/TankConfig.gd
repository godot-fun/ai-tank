class_name TankConfig

const tile_size: int = 60

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
	var grid_size: Vector2i
	var hp: int
	var max_hp: int
	var speed: float
	var bullet_speed: float
	var bullet_damage: int
	var fire_interval: float
	var invincible: bool
	var bullet_resource: String
	var fire_sound_resource: String
	var tank_resource: String
	var script_resource: String

	func _init(
		_id: int,
		_team: int,
		_grid_size: Vector2i,
		_hp: int,
		_max_hp: int,
		_speed: float,
		_bullet_speed: float,
		_bullet_damage: int,
		_fire_interval: float,
		_invincible: bool,
		_bullet_resource: String,
		_fire_sound_resource: String,
		_tank_resource: String,
		_script_resource: String,
	):
		id = _id
		team = _team
		grid_size = _grid_size
		hp = _hp
		max_hp = _max_hp
		speed = _speed
		bullet_speed = _bullet_speed
		bullet_damage = _bullet_damage
		fire_interval = _fire_interval
		invincible = _invincible
		bullet_resource = _bullet_resource
		fire_sound_resource = _fire_sound_resource
		tank_resource = _tank_resource
		script_resource = _script_resource

static var my_tank: TankData = TankData.new(
	0,
	Team.PLAYER,
	Vector2i(2, 2),
	1,
	1,
	400.0,
	800.0,
	1,
	0.3,
	true,
	"res://scene/bullet/BasicBullet.tscn",
	"res://audio/sfx/shoot-basic/01.wav",
	"res://image/characters/blue_tank_1.png",
	"res://script/tank/MyTank.gd",
)

static var enemy_easy: TankData = TankData.new(
	1,
	Team.ENEMY,
	Vector2i(2, 2),
	1,
	1,
	320.0,
	800.0,
	1,
	2.0,
	false,
	"res://scene/bullet/BasicBullet.tscn",
	"",
	"res://image/characters/red_tank_1.png",
	"res://script/tank/EnemyEasy.gd",
)

static func grid_to_world(grid: Vector2i, grid_size: Vector2i) -> Vector2:
	return Vector2(
		(grid.x + grid_size.x * 0.5) * tile_size,
		(grid.y + grid_size.y * 0.5) * tile_size,
	)


static func world_to_grid(world_pos: Vector2, grid_size: Vector2i) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / tile_size - grid_size.x * 0.5),
		floori(world_pos.y / tile_size - grid_size.y * 0.5),
	)


static func is_in_bounds(grid: Vector2i, grid_size: Vector2i) -> bool:
	return grid.x >= 0 and grid.x + grid_size.x <= map_grid_width \
		and grid.y >= 0 and grid.y + grid_size.y <= map_grid_height


static func clamp_grid_to_bounds(grid: Vector2i, grid_size: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(grid.x, 0, map_grid_width - grid_size.x),
		clampi(grid.y, 0, map_grid_height - grid_size.y),
	)

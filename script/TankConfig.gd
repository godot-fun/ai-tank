class_name TankConfig

enum Team {
	PLAYER,
	ENEMY
}

const AUDIO_SHOOT_BASIC := "res://audio/sfx/shoot-basic/01.wav"
const AUDIO_TANK_DEATH := "res://audio/sfx/tank-death/01.wav"
const AUDIO_TANK_DEATH_ENEMY := "res://audio/sfx/tank-death/02.wav"

const AUDIO_BULLET_HIT_BULLET := "res://audio/sfx/emp-hit/01.wav"
const AUDIO_BULLET_HIT_TANK := "res://audio/sfx/bullet-hit-steel/05.wav"
const AUDIO_BULLET_HIT_STEEL := "res://audio/sfx/bullet-hit-steel/01.wav"
const AUDIO_BULLET_HIT_BRICK := "res://audio/sfx/bullet-hit-brick/01.wav"
const AUDIO_BULLET_HIT_WALL := "res://audio/sfx/bullet-hit-steel/05.wav"

class TankData:
	var id: int
	var team: int
	var grid_size: Vector2i
	var hp: int
	var speed: float
	var bullet_speed: float
	var bullet_damage: int
	var fire_interval: float
	var bullet_resource: String
	var fire_sound_resource: String
	var death_sound_resource: String
	var death_effect_resource: String
	var tank_resource: String
	var script_resource: String

	func _init(
		_id: int,
		_team: int,
		_grid_size: Vector2i,
		_hp: int,
		_speed: float,
		_bullet_speed: float,
		_bullet_damage: int,
		_fire_interval: float,
		_bullet_resource: String,
		_fire_sound_resource: String,
		_death_sound_resource: String,
		_death_effect_resource: String,
		_tank_resource: String,
		_script_resource: String,
	):
		id = _id
		team = _team
		grid_size = _grid_size
		hp = _hp
		speed = _speed
		bullet_speed = _bullet_speed
		bullet_damage = _bullet_damage
		fire_interval = _fire_interval
		bullet_resource = _bullet_resource
		fire_sound_resource = _fire_sound_resource
		death_sound_resource = _death_sound_resource
		death_effect_resource = _death_effect_resource
		tank_resource = _tank_resource
		script_resource = _script_resource

static var my_tank: TankData = TankData.new(
	0,
	Team.PLAYER,
	Vector2i(2, 2),
	10,
	400.0,
	800.0,
	1,
	0.3,
	"res://image/bullets/basic/blue/01.png",
	AUDIO_SHOOT_BASIC,
	AUDIO_TANK_DEATH,
	"res://image/effects/tank-explosion_sheet.png",
	"res://image/characters/blue_tank_1.png",
	"res://script/tank/MyTank.gd",
)

static var partner_tank: TankData = TankData.new(
	2,
	Team.PLAYER,
	Vector2i(2, 2),
	10,
	360.0,
	800.0,
	1,
	0.45,
	"res://image/bullets/basic/red/01.png",
	AUDIO_SHOOT_BASIC,
	AUDIO_TANK_DEATH,
	"res://image/effects/tank-explosion_sheet.png",
	"res://image/characters/red_tank_1.png",
	"res://script/tank/PartnerTank.gd",
)

static var enemy_easy: TankData = TankData.new(
	1,
	Team.ENEMY,
	Vector2i(2, 2),
	1,
	320.0,
	800.0,
	1,
	2.0,
	"res://image/bullets/basic/gray/01.png",
	"",
	AUDIO_TANK_DEATH_ENEMY,
	"res://image/effects/tank-explosion_sheet.png",
	"res://image/characters/tank_1.png",
	"res://script/tank/EnemyEasy.gd",
)

static var only_fire_enemy: TankData = TankData.new(
	1,
	Team.ENEMY,
	Vector2i(2, 2),
	10,
	320.0,
	800.0,
	1,
	2.0,
	"res://image/bullets/basic/gray/02.png",
	"",
	AUDIO_TANK_DEATH_ENEMY,
	"res://image/effects/tank-explosion_sheet.png",
	"res://image/characters/tank_2.png",
	"res://script/tank/OnlyFireEnemy.gd",
)

static func grid_to_world(grid: Vector2i, grid_size: Vector2i) -> Vector2:
	return Vector2((grid.x + grid_size.x * 0.5) * TileConfig.TILE_SIZE, (grid.y + grid_size.y * 0.5) * TileConfig.TILE_SIZE)


static func world_to_grid(world_pos: Vector2, grid_size: Vector2i) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / TileConfig.TILE_SIZE - grid_size.x * 0.5),
		floori(world_pos.y / TileConfig.TILE_SIZE - grid_size.y * 0.5),
	)


static func is_in_bounds(grid: Vector2i, grid_size: Vector2i) -> bool:
	return grid.x >= 0 and grid.x + grid_size.x <= TileConfig.MAP_GRID_WIDTH \
		and grid.y >= 0 and grid.y + grid_size.y <= TileConfig.MAP_GRID_HEIGHT


static func clamp_grid_to_bounds(grid: Vector2i, grid_size: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(grid.x, 0, TileConfig.MAP_GRID_WIDTH - grid_size.x),
		clampi(grid.y, 0, TileConfig.MAP_GRID_HEIGHT - grid_size.y),
	)

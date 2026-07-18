class_name TankConfig

enum Team {
	PLAYER,
	ENEMY
}

enum Appearance {
	blue,
	green,
	gray,
	red
}


const DEFAULT_TANK_SPEED := 400.0
const DEFAULT_ENEMY_TANK_SPEED := 320.0
const DEFAULT_TANK_HP: int = 1


const DEFAULT_BULLET_SPEED := 800.0
const DEFAULT_BULLET_SIZE := 0.6
const DEFAULT_BULLET_FIRE_INTERVAL := 1
const DEFAULT_ENEMY_BULLET_FIRE_INTERVAL := 3

const EFFECT_TANK_PARTNER_EXPLOSION := "res://image/effects/tank_partnet_explosion.png"
const EFFECT_TANK_ENEMY_EXPLOSION := "res://image/effects/tank_enemy_explosion.png"
const EFFECT_BULLET_HIT_BULLET := "res://image/effects/bullet_hit_bullet.png"
const EFFECT_BULLET_HIT_ENEMY := "res://image/effects/bullet_hit_enemy.png"
const EFFECT_BULLET_HIT_STEEL := "res://image/effects/bullet_hit_steel.png"
const EFFECT_BULLET_HIT_BRICK := "res://image/effects/bullet_hit_brick.png"

const ENEMY_RED_ID_RANGE := Vector2i(300, 400)
const SCRIPT_ENEMY_EASY := "res://script/tank/EnemyEasy.gd"

static var tank_datas: Dictionary[int, TankData] = {}

class TankData:
	var id: int
	var team: int
	var grid_size: Vector2i
	var hp: int
	var speed: float
	var bullet_speed: float
	var bullet_damage: int
	var bullet_size: float
	var bullet_fire_interval: float
	var bullet_resource: String
	var fire_sound_resource: SoundEffect
	var death_sound_resource: SoundEffect
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
		_bullet_size: float,
		_bullet_fire_interval: float,
		_bullet_resource: String,
		_fire_sound_resource: SoundEffect,
		_death_sound_resource: SoundEffect,
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
		bullet_size = _bullet_size
		bullet_fire_interval = _bullet_fire_interval
		bullet_resource = _bullet_resource
		fire_sound_resource = _fire_sound_resource
		death_sound_resource = _death_sound_resource
		death_effect_resource = _death_effect_resource
		tank_resource = _tank_resource
		script_resource = _script_resource
		add_to_tank_datas()

	func add_to_tank_datas() -> void:
		if TankConfig.tank_datas.has(id):
			Log.error("tank config duplicate id:[{}]", id)
			return
		TankConfig.tank_datas[id] = self
		pass

static var my_tank: TankData = TankData.new(
	0,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP,
	DEFAULT_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/blue/1.png",
	AudioConfig.TANK_FIRE,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/blue_tank_1.png",
	"res://script/tank/MyTank.gd",
)

static var partner_tank_1: TankData = TankData.new(
	11,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP,
	DEFAULT_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/1.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_1.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_2: TankData = TankData.new(
	12,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + 1,
	DEFAULT_TANK_SPEED * 1.1,
	DEFAULT_BULLET_SPEED * 1.1,
	1,
	DEFAULT_BULLET_SIZE * 1.1,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/2.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_2.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_3: TankData = TankData.new(
	13,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + 1,
	DEFAULT_TANK_SPEED * 1.2,
	DEFAULT_BULLET_SPEED * 1.2,
	1,
	DEFAULT_BULLET_SIZE * 1.2,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/3.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_3.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_4: TankData = TankData.new(
	14,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + 2,
	DEFAULT_TANK_SPEED * 1.3,
	DEFAULT_BULLET_SPEED * 1.3,
	1,
	DEFAULT_BULLET_SIZE * 1.3,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/4.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_4.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_5: TankData = TankData.new(
	15,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + 2,
	DEFAULT_TANK_SPEED * 1.4,
	DEFAULT_BULLET_SPEED * 1.4,
	1,
	DEFAULT_BULLET_SIZE * 1.4,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/5.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_5.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_6: TankData = TankData.new(
	16,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + 3,
	DEFAULT_TANK_SPEED * 1.5,
	DEFAULT_BULLET_SPEED * 1.5,
	1,
	DEFAULT_BULLET_SIZE * 1.5,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/6.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_6.png",
	"res://script/tank/PartnerTank.gd",
)

# ----------------------------------------------------------------------------------------------------------------------
static var only_fire_enemy: TankData = TankData.new(
	99,
	Team.ENEMY,
	Vector2i(2, 2),
	10,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/basic/gray/02.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/gray_tank_2.png",
	"res://script/tank/OnlyFireEnemy.gd",
)

# ----------------------------------------------------------------------------------------------------------------------
static var enemy_easy: TankData = TankData.new(
	100,
	Team.ENEMY,
	Vector2i(2, 2), 
	DEFAULT_TANK_HP,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/gray/1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/gray_tank_1.png",
	SCRIPT_ENEMY_EASY
)

static var elite_enemy_easy: TankData = TankData.new(
	110,
	Team.ENEMY,
	Vector2i(3, 3), 
	DEFAULT_TANK_HP + 5,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE * 3,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL * 0.7,
	"res://image/bullets/tank/gray/5.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/gray_tank_7.png",
	SCRIPT_ENEMY_EASY
)

static var boss_enemy_easy: TankData = TankData.new(
	120,
	Team.ENEMY,
	Vector2i(4, 4), 
	DEFAULT_TANK_HP + 10,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE * 4,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL * 0.6,
	"res://image/bullets/tank/gray/5.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/red_tank_7.png",
	SCRIPT_ENEMY_EASY
)

static var enemy_red_easy: TankData = TankData.new(
	300,
	Team.ENEMY,
	Vector2i(2, 2),
	2,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/red/1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/red_tank_4.png",
	SCRIPT_ENEMY_EASY
)
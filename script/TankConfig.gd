class_name TankConfig

enum Team {
	PLAYER,
	ENEMY
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

static var tank_datas: Dictionary[int, TankData] = {}
static var clone_tank_datas: Dictionary[int, TankData] = {}

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

	func clone() -> TankData:
		return TankData.new(
			id,
			team,
			grid_size,
			hp,
			speed,
			bullet_speed,
			bullet_damage,
			bullet_size,
			bullet_fire_interval,
			bullet_resource,
			fire_sound_resource,
			death_sound_resource,
			death_effect_resource,
			tank_resource,
			script_resource
		)
	
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
	"res://image/bullets/basic/blue/01.png",
	AudioConfig.TANK_FIRE,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/blue_tank_1.png",
	"res://script/tank/MyTank.gd",
)

static var partner_tank: TankData = TankData.new(
	2,
	Team.PLAYER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP,
	DEFAULT_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/basic/green/01.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_6.png",
	"res://script/tank/PartnerTank.gd",
)

static var enemy_easy: TankData = TankData.new(
	10,
	Team.ENEMY,
	Vector2i(2, 2), 
	DEFAULT_TANK_HP,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	1,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/basic/gray/01.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/tank_1.png",
	"res://script/tank/EnemyEasy.gd",
)

static var only_fire_enemy: TankData = TankData.new(
	11,
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
	"res://image/characters/tank_2.png",
	"res://script/tank/OnlyFireEnemy.gd",
)

static func init_datas() -> void:
	if !clone_tank_datas.is_empty():
		return
	tank_datas[my_tank.id] = my_tank
	tank_datas[partner_tank.id] = partner_tank
	tank_datas[enemy_easy.id] = enemy_easy
	tank_datas[only_fire_enemy.id] = only_fire_enemy
	for data: TankData in tank_datas.values():
		clone_tank_datas[data.id] = data.clone()
	pass

static func refresh_datas() -> void:
	my_tank = clone_tank_datas[my_tank.id]
	partner_tank = clone_tank_datas[partner_tank.id]
	enemy_easy = clone_tank_datas[enemy_easy.id]
	only_fire_enemy = clone_tank_datas[only_fire_enemy.id]
	
	tank_datas.clear()
	clone_tank_datas.clear()
	init_datas()
	pass
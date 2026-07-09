class_name TankConfig

enum Team {
	PLAYER,
	ENEMY
}



const EFFECT_TANK_PARTNER_EXPLOSION := "res://image/effects/tank_partnet_explosion.png"
const EFFECT_TANK_ENEMY_EXPLOSION := "res://image/effects/tank_enemy_explosion.png"
const EFFECT_BULLET_HIT_BULLET := "res://image/effects/bullet_hit_bullet.png"
const EFFECT_BULLET_HIT_ENEMY := "res://image/effects/bullet_hit_enemy.png"
const EFFECT_BULLET_HIT_STEEL := "res://image/effects/bullet_hit_steel.png"
const EFFECT_BULLET_HIT_BRICK := "res://image/effects/bullet_hit_brick.png"

class TankData:
	var id: int
	var team: int
	var grid_size: Vector2i
	var hp: int
	var speed: float
	var bullet_speed: float
	var bullet_damage: int
	var bullet_size: float
	var fire_interval: float
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
		_fire_interval: float,
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
	1,
	400.0,
	800.0,
	1,
	0.6,
	0.3,
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
	1,
	360.0,
	800.0,
	1,
	0.6,
	0.45,
	"res://image/bullets/basic/red/01.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
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
	0.6,
	2.0,
	"res://image/bullets/basic/gray/01.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
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
	0.6,
	2.0,
	"res://image/bullets/basic/gray/02.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/tank_2.png",
	"res://script/tank/OnlyFireEnemy.gd",
)


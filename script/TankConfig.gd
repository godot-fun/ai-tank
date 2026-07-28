class_name TankConfig

enum Team {
	PLAYER,
	PARTNER,
	ENEMY,
	ENEMY_JEEP,
	ELITE_ENEMY,
	BOSS_ENEMY,
}


const DEFAULT_TANK_SPEED := 280.0
const DEFAULT_ENEMY_TANK_SPEED := 300.0
const DEFAULT_TANK_HP: int = 1


const DEFAULT_BULLET_SPEED := 700.0
const DEFAULT_BULLET_SIZE := 1.0
const DEFAULT_BULLET_FIRE_INTERVAL := 1.2
const DEFAULT_ENEMY_BULLET_FIRE_INTERVAL := 3
const DEFAULT_BULLET_DAMAGE := 1

const EFFECT_TANK_PARTNER_EXPLOSION := "res://image/effects/tank_partnet_explosion.png"
const EFFECT_TANK_ENEMY_EXPLOSION := "res://image/effects/tank_enemy_explosion.png"
const EFFECT_BULLET_HIT_BULLET := "res://image/effects/bullet_hit_bullet.png"
const EFFECT_BULLET_HIT_ENEMY := "res://image/effects/bullet_hit_enemy.png"
const EFFECT_BULLET_HIT_STEEL := "res://image/effects/bullet_hit_steel.png"
const EFFECT_BULLET_HIT_BRICK := "res://image/effects/bullet_hit_brick.png"

const SCRIPT_ENEMY_EASY := "res://script/tank/EnemyEasy.gd"
const SCRIPT_ENEMY_EAGLE := "res://script/tank/EnemyEagle.gd"
const SCRIPT_ENEMY_BOSS_2_CANNON := "res://script/tank/EnemyBoss2Cannon.gd"
const SCRIPT_ENEMY_BOSS_4_CANNON := "res://script/tank/EnemyBoss4Cannon.gd"

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
	Team.PARTNER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP,
	DEFAULT_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE,
	DEFAULT_BULLET_SIZE,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/1.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_1.png",
	"res://script/tank/PartnerSmartTank.gd",
)

static var partner_tank_2: TankData = TankData.new(
	12,
	Team.PARTNER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP,
	DEFAULT_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE,
	DEFAULT_BULLET_SIZE,
	DEFAULT_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/green/2.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_2.png",
	"res://script/tank/PartnerSmartTank.gd",
)

static var partner_tank_3: TankData = TankData.new(
	13,
	Team.PARTNER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + TankHpBuff.EFFECT_VALUE,
	DEFAULT_TANK_SPEED + TankSpeedBuff.EFFECT_VALUE,
	DEFAULT_BULLET_SPEED + BulletSpeedBuff.EFFECT_VALUE,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE,
	DEFAULT_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE,
	"res://image/bullets/tank/green/3.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_3.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_4: TankData = TankData.new(
	14,
	Team.PARTNER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP,
	DEFAULT_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE,
	DEFAULT_BULLET_SIZE,
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
	Team.PARTNER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + TankHpBuff.EFFECT_VALUE * 2,
	DEFAULT_TANK_SPEED + TankSpeedBuff.EFFECT_VALUE * 2,
	DEFAULT_BULLET_SPEED + BulletSpeedBuff.EFFECT_VALUE * 2,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 2,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 2,
	DEFAULT_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 2,
	"res://image/bullets/tank/green/5.png",
	null,
	AudioConfig.TANK_DEATH,
	EFFECT_TANK_PARTNER_EXPLOSION,
	"res://image/characters/green_tank_5.png",
	"res://script/tank/PartnerTank.gd",
)

static var partner_tank_6: TankData = TankData.new(
	16,
	Team.PARTNER,
	Vector2i(2, 2),
	DEFAULT_TANK_HP + TankHpBuff.EFFECT_VALUE,
	DEFAULT_TANK_SPEED + TankSpeedBuff.EFFECT_VALUE,
	DEFAULT_BULLET_SPEED + BulletSpeedBuff.EFFECT_VALUE,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE,
	DEFAULT_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE,
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
	DEFAULT_BULLET_DAMAGE,
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
	Vector2i.ONE * 2, 
	DEFAULT_TANK_HP,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/gray/1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/gray_tank_1.png",
	SCRIPT_ENEMY_EASY
)

static var enemy_jeep: TankData = TankData.new(
	101,
	Team.ENEMY_JEEP,
	Vector2i.ONE * 2, 
	DEFAULT_TANK_HP,
	DEFAULT_ENEMY_TANK_SPEED * 2,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/gray/1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/jeep_1.png",
	SCRIPT_ENEMY_EAGLE
)

static var elite_enemy_easy: TankData = TankData.new(
	150,
	Team.ELITE_ENEMY,
	Vector2i.ONE * 2, 
	DEFAULT_TANK_HP + 1,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE,
	DEFAULT_BULLET_SIZE,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL,
	"res://image/bullets/tank/red/1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/red_tank_4.png",
	SCRIPT_ENEMY_EASY
)

static var mini_boss_enemy_easy_1: TankData = TankData.new(
	110,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 3, 
	DEFAULT_TANK_HP + 10,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 2,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 2,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 2,
	"res://image/bullets/tank/boss/mini_boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/mini_boss_gray_tank_1.png",
	SCRIPT_ENEMY_EASY
)

static var mini_boss_enemy_easy_2: TankData = TankData.new(
	111,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 3, 
	DEFAULT_TANK_HP + 10,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 3,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 3,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 3,
	"res://image/bullets/tank/boss/mini_boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/mini_boss_gray_tank_2.png",
	SCRIPT_ENEMY_EASY
)

static var mini_boss_enemy_easy_3: TankData = TankData.new(
	112,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 3, 
	DEFAULT_TANK_HP + 10,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 4,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 4,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 4,
	"res://image/bullets/tank/boss/mini_boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/mini_boss_gray_tank_3.png",
	SCRIPT_ENEMY_EASY
)

static var boss_enemy_easy: TankData = TankData.new(
	120,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 4, 
	DEFAULT_TANK_HP + 20,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 4,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 4,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 4,
	"res://image/bullets/tank/boss/boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/boss_red_tank_1.png",
	SCRIPT_ENEMY_EASY
)

static var boss_enemy_normal: TankData = TankData.new(
	121,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 4, 
	DEFAULT_TANK_HP + 20,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 5,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 5,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 5,
	"res://image/bullets/tank/boss/boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/boss_red_tank_2.png",
	SCRIPT_ENEMY_EASY
)


static var enemy_boss_2_cannon: TankData = TankData.new(
	130,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 4, 
	DEFAULT_TANK_HP + 20,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 6,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 6,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 6,
	"res://image/bullets/tank/boss/boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/boss_purple_2_cannon.png",
	SCRIPT_ENEMY_BOSS_2_CANNON
)

static var enemy_boss_4_cannon: TankData = TankData.new(
	131,
	Team.BOSS_ENEMY,
	Vector2i.ONE * 4, 
	DEFAULT_TANK_HP + 20,
	DEFAULT_ENEMY_TANK_SPEED,
	DEFAULT_BULLET_SPEED,
	DEFAULT_BULLET_DAMAGE + BulletSizeBuff.BULLET_DAMAGE_EFFECT_VALUE * 7,
	DEFAULT_BULLET_SIZE + BulletSizeBuff.BULLET_SIZE_EFFECT_VALUE * 7,
	DEFAULT_ENEMY_BULLET_FIRE_INTERVAL - BulletFireIntervalBuff.EFFECT_VALUE * 7,
	"res://image/bullets/tank/boss/boss_1.png",
	null,
	AudioConfig.TANK_DEATH_ENEMY,
	EFFECT_TANK_ENEMY_EXPLOSION,
	"res://image/characters/boss_purple_4_cannon.png",
	SCRIPT_ENEMY_BOSS_4_CANNON
)

# ----------------------------------------------------------------------------------------------------------------------
static var player_faction: Array[TankConfig.Team] = [TankConfig.Team.PLAYER, TankConfig.Team.PARTNER]
static var enemy_faction: Array[TankConfig.Team] = [TankConfig.Team.ENEMY, TankConfig.Team.ENEMY_JEEP, TankConfig.Team.ELITE_ENEMY, TankConfig.Team.BOSS_ENEMY]


static func is_same_faction(a: Team, b: Team) -> bool:
	return (a in player_faction and b in player_faction) or (a in enemy_faction and b in enemy_faction)

static func is_player_faction(team: Team) -> bool:
	return team in player_faction

static func is_enemy_faction(team: Team) -> bool:
	return team in enemy_faction

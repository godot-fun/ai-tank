extends CharacterBody2D
class_name Tank

# tank data property
var id: int
var team: int
var hp: int
var max_hp: int
var speed: float
var bullet_speed: float
var bullet_damage: int
var fire_interval: float
var invincible: bool

# custom property
var fire_cooldown := 0.0


func apply_data(data: TankConfig.TankData) -> void:
	id = data.id
	team = data.team
	hp = data.hp
	max_hp = data.max_hp
	speed = data.speed
	bullet_speed = data.bullet_speed
	bullet_damage = data.bullet_damage
	fire_interval = data.fire_interval
	invincible = data.invincible


func take_damage(amount: int) -> void:
	if invincible:
		return
	hp = maxi(hp - amount, 0)


func get_team() -> int:
	return team


func can_fire() -> bool:
	return fire_cooldown <= 0.0


func update_fire_cooldown(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta


func start_fire_cooldown() -> void:
	fire_cooldown = fire_interval

extends CharacterBody2D
class_name Tank

# tank data property
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
var tank_resource: String
var script_resource: String

# custom property
var fire_cooldown := 0.0
var grid_pos := Vector2i.ZERO
var facing := Vector2i(0, -1)
var moving := false

@onready var sprite: Sprite2D = $Sprite2D


func apply_data(data: TankConfig.TankData) -> void:
	id = data.id
	team = data.team
	grid_size = data.grid_size
	hp = data.hp
	max_hp = data.max_hp
	speed = data.speed
	bullet_speed = data.bullet_speed
	bullet_damage = data.bullet_damage
	fire_interval = data.fire_interval
	invincible = data.invincible
	bullet_resource = data.bullet_resource
	tank_resource = data.tank_resource
	script_resource = data.script_resource
	
	sprite.texture = load(data.tank_resource)
	
	scale_tank()
	pass


func can_fire() -> bool:
	return fire_cooldown <= 0.0


func update_fire_cooldown(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta


func start_fire_cooldown() -> void:
	fire_cooldown = fire_interval


func scale_tank() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(grid_size) * TankConfig.tile_size
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(TankConfig.world_to_grid(global_position, grid_size), grid_size)
	global_position = TankConfig.grid_to_world(grid_pos, grid_size)
	pass


func update_facing(direction: Vector2i) -> void:
	facing = direction
	sprite.rotation = Vector2(direction).angle() + PI / 2.0
	pass


func affected_by_ice() -> bool:
	return false

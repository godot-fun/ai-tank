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

const ICE_SLIDE_TILES := 2

# custom property
var fire_cooldown := 0.0
var grid_pos := Vector2i.ZERO
var facing := Vector2i(0, -1)
var moving := false
var _is_ice_slide := false
var _ice_slides_remaining := 0

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
	return true


func try_move(direction: Vector2i, ice_slide: bool = false) -> void:
	if not ice_slide:
		_ice_slides_remaining = 0

	update_facing(direction)

	var target_grid := grid_pos + direction
	if not TankConfig.is_in_bounds(target_grid, grid_size):
		return
	if TileHelper.is_area_blocked_for_tank(target_grid, grid_size):
		return

	_is_ice_slide = ice_slide
	grid_pos = target_grid
	moving = true

	var move_duration := TankConfig.tile_size / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", TankConfig.grid_to_world(grid_pos, grid_size), move_duration)
	tween.finished.connect(on_move_finished)
	pass


func on_move_finished() -> void:
	moving = false
	if affected_by_ice() and not _is_ice_slide and TileHelper.is_area_on_ice(grid_pos, grid_size):
		_ice_slides_remaining = ICE_SLIDE_TILES
	if affected_by_ice() and _ice_slides_remaining > 0:
		_ice_slides_remaining -= 1
		try_move(facing, true)
		return
	on_move_continue()
	pass


func on_move_continue() -> void:
	pass

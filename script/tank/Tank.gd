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
var facing := Vector2i.UP
var moving := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	Log.info("map size:[{} * {}]", TankConfig.map_grid_width, TankConfig.map_grid_height)
	start()
	TankHelper.register_tank(self)
	pass


func _exit_tree() -> void:
	TankHelper.unregister_tank(self)
	pass


func _physics_process(delta: float) -> void:
	update_fire_cooldown(delta)
	update(delta)
	pass


func start() -> void:
	pass


func update(_delta: float) -> void:
	pass


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

# ----------------------------------------------------------------------------------------------------------------------

func scale_tank() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(grid_size) * TankConfig.tile_size
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(TankConfig.world_to_grid(global_position, grid_size), grid_size)
	global_position = TankConfig.grid_to_world(grid_pos, grid_size)
	pass

# ----------------------------------------------------------------------------------------------------------------------
func can_fire() -> bool:
	return fire_cooldown <= 0.0


func update_fire_cooldown(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta


func start_fire_cooldown() -> void:
	fire_cooldown = fire_interval


func try_shoot() -> void:
	if not can_fire():
		return

	var bullet_scene: PackedScene = load(bullet_resource)
	var bullet: BasicBullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var spawn_offset := Vector2(facing) * TankConfig.tile_size
	bullet.launch(global_position + spawn_offset, facing, team, bullet_speed, bullet_damage)
	start_fire_cooldown()
	pass


# ----------------------------------------------------------------------------------------------------------------------
const ICE_SLIDE_TILES := 2

func update_facing(direction: Vector2i) -> void:
	facing = direction
	sprite.rotation = Vector2(direction).angle() + PI / 2.0
	pass

func try_move(direction: Vector2i, ice_slides_left: int = -1) -> void:
	update_facing(direction)

	var target_grid := grid_pos + direction
	if TankHelper.is_move_blocked(target_grid, grid_size, self):
		return

	grid_pos = target_grid
	moving = true

	var move_duration := TankConfig.tile_size / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", TankConfig.grid_to_world(grid_pos, grid_size), move_duration)
	tween.finished.connect(on_move_finished.bind(ice_slides_left))
	pass


func on_move_finished(ice_slides_left: int) -> void:
	moving = false
	if ice_slides_left == -1 and TileHelper.is_area_on_ice(grid_pos, grid_size):
		ice_slides_left = ICE_SLIDE_TILES
	if ice_slides_left > 0:
		try_move(facing, ice_slides_left - 1)
		return
	pass


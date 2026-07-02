extends CharacterBody2D
class_name Tank

# tank data property
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


# custom property
var fire_cooldown := 0.0
var grid_pos := Vector2i.ZERO
var facing := Vector2i.UP
var moving := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	Log.info("map size:[{} * {}]", TankConfig.map_grid_width, TankConfig.map_grid_height)
	scale_tank()
	start()
	TankHelper.register_tank(self)
	pass


func _exit_tree() -> void:
	TankHelper.unregister_tank(self)
	pass


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
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
	speed = data.speed
	bullet_speed = data.bullet_speed
	bullet_damage = data.bullet_damage
	fire_interval = data.fire_interval
	bullet_resource = data.bullet_resource
	fire_sound_resource = data.fire_sound_resource
	death_sound_resource = data.death_sound_resource
	death_effect_resource = data.death_effect_resource
	tank_resource = data.tank_resource
	script_resource = data.script_resource
	pass

# ----------------------------------------------------------------------------------------------------------------------

func scale_tank() -> void:
	sprite.texture = load(tank_resource)

	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(grid_size) * TankConfig.tile_size
	scale = target_size / texture_size

	grid_pos = TankConfig.clamp_grid_to_bounds(TankConfig.world_to_grid(global_position, grid_size), grid_size)
	global_position = TankConfig.grid_to_world(grid_pos, grid_size)
	pass

# ----------------------------------------------------------------------------------------------------------------------
func is_alive() -> bool:
	return hp > 0


func on_die(amount: int) -> bool:
	if !is_alive() || amount <= 0 || is_queued_for_deletion():
		return false

	hp = hp - amount
	if hp > 0:
		return false

	Audio.play_sound(death_sound_resource)
	EffectAnimation2D.spawn(
		global_position,
		get_tree().current_scene,
		death_effect_resource,
		Vector2i(8, 1), 0.6
	)
	if team == TankConfig.Team.ENEMY:
		var battle_map := get_tree().current_scene
		if battle_map != null and battle_map.has_method("on_enemy_killed"):
			battle_map.call_deferred("on_enemy_killed")
	queue_free()
	return true

# ----------------------------------------------------------------------------------------------------------------------
func update_fire_cooldown(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta

func fire() -> void:
	if fire_cooldown > 0.0:
		return

	var bullet_scene: PackedScene = load(BasicBullet.SCENE)
	var bullet: BasicBullet = bullet_scene.instantiate()
	var spawn_offset := Vector2(facing) * TankConfig.tile_size
	bullet.apply_data(global_position + spawn_offset, facing, team, bullet_speed, bullet_damage, bullet_resource)
	get_tree().current_scene.add_child(bullet)

	fire_cooldown = fire_interval
	Audio.play_sound(fire_sound_resource)
	pass


# ----------------------------------------------------------------------------------------------------------------------
const ICE_SLIDE_TILES := 2

func update_facing(direction: Vector2i) -> void:
	facing = direction
	sprite.rotation = Vector2(direction).angle() + PI / 2.0
	pass

func move(direction: Vector2i, ice_slides_left: int = -1) -> void:
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
		move(facing, ice_slides_left - 1)
		return
	pass

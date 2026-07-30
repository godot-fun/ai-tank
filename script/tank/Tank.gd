extends CharacterBody2D
class_name Tank

const LOW_HP_COLOR := Color(1.0, 0.7, 0.7)

# tank data property
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


# custom property
var fire_cooldown := 0.0
var grid_pos := Vector2i.ZERO
var facing := Vector2i.UP
var moving := false
var max_hp := 1
var killed_by_tank_id := -1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	scale_tank()
	update_hp_color()
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
	physics_update(delta)
	pass

func apply_data(data: TankConfig.TankData, grid: Vector2i) -> void:
	id = data.id
	team = data.team
	grid_size = data.grid_size
	hp = data.hp
	speed = data.speed
	bullet_speed = data.bullet_speed
	bullet_damage = data.bullet_damage
	bullet_size = data.bullet_size
	bullet_fire_interval = data.bullet_fire_interval
	bullet_resource = data.bullet_resource
	fire_sound_resource = data.fire_sound_resource
	death_sound_resource = data.death_sound_resource
	death_effect_resource = data.death_effect_resource
	tank_resource = data.tank_resource
	script_resource = data.script_resource
	grid_pos = TileConfig.clamp_grid_to_bounds(grid, data.grid_size)
	global_position = TileConfig.grid_to_world(grid_pos, grid_size)
	max_hp = data.hp
	pass

# ----------------------------------------------------------------------------------------------------------------------

## 玩法根节点保持 scale=1，只缩放视觉与碰撞，避免子节点局部坐标被连带缩放。
func scale_tank() -> void:
	sprite.texture = load(tank_resource)

	var texture_size := sprite.texture.get_size()
	var target_size := Vector2(grid_size) * TileConfig.TILE_SIZE
	var scale_param := target_size / texture_size
	sprite.scale = scale_param

	collision_shape.scale = scale_param
	pass

func scale_tank_deferred() -> void:
	gdf.callable_deferred(scale_tank)
	pass

func update_hp_color() -> void:
	if max_hp <= hp:
		sprite.self_modulate = Color.WHITE
		return

	var low_hp_ratio := inverse_lerp(
		float(max_hp),
		float(TankConfig.DEFAULT_TANK_HP),
		float(clampi(hp, TankConfig.DEFAULT_TANK_HP, max_hp)),
	)
	sprite.self_modulate = Color.WHITE.lerp(LOW_HP_COLOR, low_hp_ratio)
	pass


func play_enter_animation() -> void:
	visible = false
	moving = true

	var target_pos := global_position
	global_position = Vector2(
		target_pos.x,
		target_pos.y + TileConfig.TILE_SIZE * 2,
	)
	visible = true

	var duration := global_position.distance_to(target_pos) / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_pos, duration)
	tween.finished.connect(func() -> void:
		moving = false
		global_position = TileConfig.grid_to_world(grid_pos, grid_size)
	)
	pass

# Interfac-Start
# ----------------------------------------------------------------------------------------------------------------------
func start() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

# ----------------------------------------------------------------------------------------------------------------------
func is_alive() -> bool:
	return hp > 0

func is_enemy() -> bool:
	return team == TankConfig.Team.ENEMY || team == TankConfig.Team.ENEMY_JEEP || team == TankConfig.Team.ELITE_ENEMY || team == TankConfig.Team.BOSS_ENEMY

func is_alive_enemy() -> bool:
	return is_enemy() && is_alive()


# true is die
func take_damage(amount: int, damage_from_tank_id: int = -1) -> bool:
	if !is_alive() || amount <= 0 || is_queued_for_deletion():
		return false

	hp = hp - amount
	if hp > 0:
		SpriteUtils.play_hit_flash(sprite)
		update_hp_color()
		return false

	Audios.play_sfx(death_sound_resource)

	sprite.visible = false
	killed_by_tank_id = damage_from_tank_id
	TankBreakEffect.spawn(global_position, sprite.scale, grid_size, sprite.rotation, sprite.texture, get_parent())
	EffectAnimation2D.spawn(
		global_position,
		get_tree().current_scene,
		death_effect_resource,
		Vector2i(4, 4), 0.5
	)
	if is_enemy():
		EventBus.events.enemy_tank_death.emit(self)	
	elif team == TankConfig.Team.PLAYER:
		EventBus.events.player_tank_death.emit(self)
	elif team == TankConfig.Team.PARTNER:
		EventBus.events.partnet_tank_death.emit(self)
	queue_free()
	return true

# ----------------------------------------------------------------------------------------------------------------------
func update_fire_cooldown(delta: float) -> void:
	if fire_cooldown > 0.0:
		fire_cooldown -= delta

func can_fire() -> bool:
	return fire_cooldown <= 0.0

func fire() -> void:
	if can_fire():
		fire_to(facing)
	pass

func fire_to(to: Vector2i) -> void:
	var bullet_scene: PackedScene = load(BasicBullet.SCENE)
	var bullet: BasicBullet = bullet_scene.instantiate()
	var spawn_offset := Vector2(to) * TileConfig.TILE_SIZE / 2
	bullet.apply_data(id, team, global_position + spawn_offset, to, bullet_speed, bullet_damage, bullet_size, bullet_resource)
	get_tree().current_scene.add_child(bullet)

	fire_cooldown = bullet_fire_interval
	if fire_sound_resource != null:
		Audios.play_sfx(fire_sound_resource)
	pass
# ----------------------------------------------------------------------------------------------------------------------
const ICE_SLIDE_TILES := 2

func update_facing(direction: Vector2i) -> void:
	facing = direction
	sprite.rotation = Vector2(direction).angle() + PI / 2.0
	pass

## extra_steps: 本步之后同方向还要连走几格；-1 表示未指定，落地后若在冰面则自动滑 ICE_SLIDE_TILES。
func move(direction: Vector2i, extra_steps: int = -1) -> void:
	update_facing(direction)

	var target_grid := grid_pos + direction
	if TankHelper.is_move_blocked(target_grid, grid_size, self):
		return

	grid_pos = target_grid
	moving = true

	var move_duration := TileConfig.TILE_SIZE / speed
	var tween := create_tween()
	tween.tween_property(self, "global_position", TileConfig.grid_to_world(grid_pos, grid_size), move_duration)
	tween.finished.connect(on_move_finished.bind(extra_steps))
	pass


func on_move_finished(extra_steps: int) -> void:
	moving = false
	if extra_steps == -1 and TileHelper.is_area_on_ice(grid_pos, grid_size):
		extra_steps = ICE_SLIDE_TILES
	if extra_steps > 0:
		move(facing, extra_steps - 1)
		return
	pass


# ----------------------------------------------------------------------------------------------------------------------
# AI
static var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

func pick_random_direction() -> Vector2i:
	directions.shuffle()
	return RandomUtils.random_ele(directions)


func pick_random_not_blocked_direction() -> Vector2i:
	directions.shuffle()

	for direction in directions:
		var target_grid := grid_pos + direction
		if not TankHelper.is_move_blocked(target_grid, grid_size, self):
			return direction

	return RandomUtils.random_ele(directions)

func pick_direction_toward(target_grid: Vector2i) -> Vector2i:
	var diff := target_grid - grid_pos
	if diff == Vector2i.ZERO:
		return pick_random_direction()

	var candidates: Array[Vector2i] = []
	if diff.x != 0:
		candidates.append(Vector2i.RIGHT if signi(diff.x) > 0 else Vector2i.LEFT)
	if diff.y != 0:
		candidates.append(Vector2i.DOWN if signi(diff.y) > 0 else Vector2i.UP)

	candidates.shuffle()
	for direction in candidates:
		if not TankHelper.is_move_blocked(grid_pos + direction, grid_size, self):
			return direction

	return pick_random_direction()
# Interfac-End

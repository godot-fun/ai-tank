class_name BasicBullet
extends Area2D

const SCENE := "res://scene/bullet/BasicBullet.tscn"

var direction := Vector2i.ZERO
var speed := 0.0
var damage := 0
var bullet_size := 0.6
var team := TankConfig.Team.PLAYER
var sprite_bullet_resource := ""

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(on_body_entered)
	area_entered.connect(on_area_entered)
	scale_sprite()
	pass


func scale_sprite() -> void:
	sprite.texture = load(sprite_bullet_resource)

	var texture_size := sprite.texture.get_size()
	var target_size := Vector2.ONE * TileConfig.TILE_SIZE * bullet_size
	scale = target_size / texture_size
	
	rotation = Vector2(direction).angle() + PI / 2.0
	pass

func apply_data(
	from: Vector2,
	dir: Vector2i,
	bullet_team: int,
	bullet_speed: float,
	bullet_damage: int,
	_bullet_size: float,
	bullet_resource: String,
) -> void:
	sprite_bullet_resource = bullet_resource
	global_position = from
	direction = dir
	team = bullet_team
	speed = bullet_speed
	damage = bullet_damage
	bullet_size = _bullet_size
	pass


func _physics_process(delta: float) -> void:
	global_position += Vector2(direction) * speed * delta
	if is_out_of_bounds():
		queue_free()
	pass


func is_out_of_bounds() -> bool:
	var map_width := TileConfig.MAP_GRID_WIDTH * TileConfig.TILE_SIZE
	var map_height := TileConfig.MAP_GRID_HEIGHT * TileConfig.TILE_SIZE
	return global_position.x < 0.0 \
		or global_position.y < 0.0 \
		or global_position.x > map_width \
		or global_position.y > map_height


func on_area_entered(area: Area2D) -> void:
	if not area is BasicBullet:
		return

	var other := area as BasicBullet
	if other.team == team:
		return

	# Only one bullet handles the collision to avoid double-free.
	if get_instance_id() > other.get_instance_id():
		return

	Audios.play_sfx(AudioConfig.BULLET_HIT_BULLET)
	EffectAnimation2D.spawn(global_position, 
		get_tree().current_scene,
		TankConfig.EFFECT_BULLET_HIT_BULLET, 
		Vector2i(4, 4), 0.3, 27)
	queue_free()
	other.queue_free()
	pass


func on_body_entered(body: Node2D) -> void:
	if body is Tank:
		var tank := body as Tank
		if tank.team == team:
			return
		if !tank.take_damage(damage):
			Audios.play_sfx(AudioConfig.BULLET_HIT_TANK)
			EffectAnimation2D.spawn(global_position, 
				get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_ENEMY, 
				Vector2i(6, 3), 0.3, 27)
		queue_free()
	elif body is Tile:
		var tile := body as Tile
		if not tile.blocks_bullet():
			return
		tile.take_damage(damage)
		queue_free()
		if tile is BrickWall:
			Audios.play_sfx(AudioConfig.BULLET_HIT_BRICK)
			EffectAnimation2D.spawn(global_position, 
				get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_BRICK, 
				Vector2i(4, 4), 0.3, 27)
		else:
			Audios.play_sfx(AudioConfig.BULLET_HIT_STEEL)
			EffectAnimation2D.spawn(global_position, 
				get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_STEEL, 
				Vector2i(6, 3), 0.3, 27)
	pass

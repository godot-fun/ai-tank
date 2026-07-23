class_name BasicBullet
extends Area2D

const SCENE := "res://scene/bullet/BasicBullet.tscn"

var id: int = 0
var direction := Vector2i.ZERO
var speed := 0.0
var damage := 0
var bullet_size := 0.0
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
	tank_id: int,
	tank_team: int,
	from: Vector2,
	dir: Vector2i,
	bullet_speed: float,
	bullet_damage: int,
	_bullet_size: float,
	bullet_resource: String,
) -> void:
	id = tank_id
	team = tank_team
	sprite_bullet_resource = bullet_resource
	global_position = from
	direction = dir
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
	if TankConfig.is_same_faction(other.team, team):
		return

	# Only one bullet handles the collision to avoid double-free.
	if get_instance_id() > other.get_instance_id():
		return

	Audios.play_sfx(AudioConfig.BULLET_HIT_BULLET)
	EffectAnimation2D.spawn(global_position, 
		get_tree().current_scene,
		TankConfig.EFFECT_BULLET_HIT_BULLET, 
		Vector2i(4, 4), 0.3 * bullet_size, 27)

	var min_damage := mini(damage, other.damage)
	damage = damage - min_damage
	other.damage = other.damage - min_damage
	if damage <= 0:
		queue_free()
	if other.damage <= 0:
		other.queue_free()
	pass


func on_body_entered(body: Node2D) -> void:
	if body is Tank:
		var tank := body as Tank
		if TankConfig.is_same_faction(tank.team, team):
			return
		if !tank.take_damage(damage, id):
			Audios.play_sfx(AudioConfig.BULLET_HIT_TANK)
			EffectAnimation2D.spawn(global_position, 
				get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_ENEMY, 
				Vector2i(6, 3), 0.3 * bullet_size, 27)
		queue_free()
	elif body is Tile:
		var tile := body as Tile
		if not tile.blocks_bullet():
			return
		tile.take_damage(damage)
		queue_free()
		if tile is BrickWall:
			Audios.play_sfx(AudioConfig.BULLET_HIT_BRICK)
			EffectAnimation2D.spawn(tile.global_position, 
				get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_BRICK, 
				Vector2i(4, 4), 0.3 * bullet_size, 27)
		else:
			var effect_position := global_position
			# Boss bullets can pierce and destroy steel walls.
			if team == TankConfig.Team.BOSS_ENEMY:
				tile.destroy()
				effect_position = tile.global_position
			Audios.play_sfx(AudioConfig.BULLET_HIT_STEEL)
			EffectAnimation2D.spawn(effect_position, 
				get_tree().current_scene,
				TankConfig.EFFECT_BULLET_HIT_STEEL, 
				Vector2i(6, 3), 0.3 * bullet_size, 27)
	pass

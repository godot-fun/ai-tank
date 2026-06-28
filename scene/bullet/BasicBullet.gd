class_name BasicBullet
extends Area2D

const BULLET_SIZE_RATIO := 0.5
const CLASH_SOUND_RESOURCES: Array[String] = [
	"res://audio/sfx/bullet-hit-steel/01.wav",
	"res://audio/sfx/bullet-hit-steel/02.wav",
	"res://audio/sfx/bullet-hit-steel/03.wav",
	"res://audio/sfx/bullet-hit-steel/04.wav",
	"res://audio/sfx/bullet-hit-steel/05.wav",
]

var direction := Vector2i.ZERO
var speed := 0.0
var damage := 0
var team := TankConfig.Team.PLAYER

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(on_body_entered)
	area_entered.connect(on_area_entered)
	scale_sprite()
	pass


func launch(from: Vector2, dir: Vector2i, bullet_team: int, bullet_speed: float, bullet_damage: int) -> void:
	global_position = from
	direction = dir
	team = bullet_team
	speed = bullet_speed
	damage = bullet_damage
	sprite.rotation = Vector2(direction).angle() + PI / 2.0
	pass


func _physics_process(delta: float) -> void:
	global_position += Vector2(direction) * speed * delta
	if is_out_of_bounds():
		queue_free()
	pass


func scale_sprite() -> void:
	var texture_size := sprite.texture.get_size()
	var target_size := Vector2.ONE * TankConfig.tile_size * BULLET_SIZE_RATIO
	scale = target_size / texture_size
	pass


func is_out_of_bounds() -> bool:
	var map_width := TankConfig.map_grid_width * TankConfig.tile_size
	var map_height := TankConfig.map_grid_height * TankConfig.tile_size
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

	Audio.play_sound(RandomUtils.random_ele(CLASH_SOUND_RESOURCES))
	queue_free()
	other.queue_free()
	pass


func on_body_entered(body: Node2D) -> void:
	if body is Tank:
		var tank := body as Tank
		if tank.team == team:
			return
		tank.take_damage(damage)
		queue_free()
	elif body is Tile:
		var tile := body as Tile
		if not tile.blocks_bullet():
			return
		tile.take_damage(damage)
		queue_free()
	elif body is Eagle:
		var eagle := body as Eagle
		if not eagle.blocks_bullet():
			return
		eagle.take_damage(damage, team)
		queue_free()
	pass

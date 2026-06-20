class_name BasicBullet
extends Area2D

const BULLET_SIZE_RATIO := 0.5

var direction := Vector2i.ZERO
var speed := 0.0
var damage := 0
var owner_tank: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(on_body_entered)
	scale_sprite()
	pass


func launch(from: Vector2, dir: Vector2i, tank: Node2D, bullet_speed: float, bullet_damage: int) -> void:
	global_position = from
	direction = dir
	speed = bullet_speed
	damage = bullet_damage
	owner_tank = tank
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


func on_body_entered(body: Node2D) -> void:
	if body == owner_tank:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
	pass

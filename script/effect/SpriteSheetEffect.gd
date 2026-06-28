extends Node2D
class_name SpriteSheetEffect

const ANIMATION_NAME := "default"

var _sheet_resource: String
var _frame_size: Vector2i
var _frame_count: int
var _animation_fps: float
var _display_size: Vector2
var _animated_sprite: AnimatedSprite2D


func _ready() -> void:
	z_index = 5

	_animated_sprite = AnimatedSprite2D.new()
	add_child(_animated_sprite)

	_setup_sprite_frames()
	_scale_to_display_size()
	_animated_sprite.animation_finished.connect(_on_animation_finished)
	_animated_sprite.play(ANIMATION_NAME)
	pass


func _setup_sprite_frames() -> void:
	var sheet: Texture2D = load(_sheet_resource)
	var frames := SpriteFrames.new()
	frames.add_animation(ANIMATION_NAME)
	frames.set_animation_speed(ANIMATION_NAME, _animation_fps)
	frames.set_animation_loop(ANIMATION_NAME, false)

	for i in _frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * _frame_size.x, 0, _frame_size.x, _frame_size.y)
		frames.add_frame(ANIMATION_NAME, atlas)

	_animated_sprite.sprite_frames = frames
	pass


func _scale_to_display_size() -> void:
	var texture: Texture2D = _animated_sprite.sprite_frames.get_frame_texture(ANIMATION_NAME, 0)
	var texture_size := texture.get_size()
	_animated_sprite.scale = _display_size / texture_size
	pass


func _on_animation_finished() -> void:
	queue_free()
	pass


static func spawn(
	pos: Vector2,
	parent: Node,
	sheet_resource: String,
	display_size: Vector2,
	frame_size: Vector2i = Vector2i(256, 256),
	frame_count: int = 8,
	animation_fps: float = 14.0,
) -> void:
	var effect := SpriteSheetEffect.new()
	effect._sheet_resource = sheet_resource
	effect._frame_size = frame_size
	effect._frame_count = frame_count
	effect._animation_fps = animation_fps
	effect._display_size = display_size
	effect.global_position = pos
	parent.add_child(effect)
	pass

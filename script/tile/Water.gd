extends Tile
class_name Water

const WAVE_SHADER := "res://shader/water_wave.gdshader"

static var wave_material: ShaderMaterial


func start() -> void:
	z_index = ZLayers.WATER
	setup_wave_material()
	pass


func setup_physics_layers() -> void:
	collision_layer = PhysicsLayers.WATER_TILE
	collision_mask = 0
	pass


func setup_wave_material() -> void:
	if wave_material == null:
		wave_material = ShaderMaterial.new()
		wave_material.shader = load(WAVE_SHADER)
	sprite.material = wave_material
	pass


func blocks_tank() -> bool:
	return true


func blocks_bullet() -> bool:
	return false


func take_damage(_amount: int) -> void:
	pass

extends Tile
class_name Forest

const SWAY_SHADER := "res://shader/forest_sway.gdshader"

static var sway_material: ShaderMaterial


func start() -> void:
	z_index = 8
	setup_sway_material()
	pass


func setup_sway_material() -> void:
	if sway_material == null:
		sway_material = ShaderMaterial.new()
		sway_material.shader = load(SWAY_SHADER)
	sprite.material = sway_material
	pass


func blocks_tank() -> bool:
	return false


func blocks_bullet() -> bool:
	return false


func take_damage(_amount: int) -> void:
	pass

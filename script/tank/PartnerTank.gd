extends Tank
class_name PartnerTank

const BUFF_SEEK_RANGE := 5
const FORWARD_DETECT_RADIUS := TileConfig.TILE_SIZE * 0.35

var forward_shape_cast: ShapeCast2D


func start() -> void:
	facing = Vector2i.UP
	update_facing(facing)
	set_up_ray()
	pass


func set_up_ray() -> void:
	forward_shape_cast = ShapeCast2D.new()
	forward_shape_cast.name = "ForwardShapeCast"
	forward_shape_cast.enabled = true
	forward_shape_cast.exclude_parent = true
	forward_shape_cast.collide_with_areas = true
	forward_shape_cast.collide_with_bodies = true
	forward_shape_cast.collision_mask = PhysicsLayers.PARTNER_RAY_MASK
	forward_shape_cast.max_results = 8

	var shape := RectangleShape2D.new()
	shape.size = Vector2(FORWARD_DETECT_RADIUS * 2.0, FORWARD_DETECT_RADIUS * 2.0)
	forward_shape_cast.shape = shape

	add_child(forward_shape_cast)
	pass


## 选取朝向目标格的方向：优先 buff，其次最近敌人，再次跟随玩家。
func pick_partner_target_grid() -> Vector2i:
	var nearby_buff := BuffHelper.find_nearest_obtainable_buff(self, BUFF_SEEK_RANGE)
	if nearby_buff != null:
		return nearby_buff.grid_pos

	var enemy := TankHelper.find_nearest_enemy(self)
	if enemy != null:
		return enemy.grid_pos

	var leader := TankHelper.find_player()
	if leader != null and leader != self:
		return leader.grid_pos

	return Vector2i.ZERO

## 用 ShapeCast2D 检测坦克正前方最近的物体。
func ray_detect_nearest_objects_in_front(max_count: int = 2) -> Array[Node2D]:
	return ray_detect_nearest_objects_toward(facing, max_count)


## 沿指定方向扫射；同层可能命中多个，按前向投影距离取最近 max_count 个（默认 2）。
func ray_detect_nearest_objects_toward(dir: Vector2i, max_count: int = 2) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if dir == Vector2i.ZERO:
		return result

	var cast_distance := TileConfig.MAP_MAX_DISTANCE
	forward_shape_cast.position = dir
	forward_shape_cast.target_position = dir * cast_distance
	forward_shape_cast.force_shapecast_update()

	var hit_count := forward_shape_cast.get_collision_count()
	if hit_count <= 0:
		return result

	var origin := forward_shape_cast.global_position
	var dir_f := Vector2(dir)
	var hits: Array[Dictionary] = []
	for index in range(hit_count):
		var collider := forward_shape_cast.get_collider(index)
		if collider == null or collider == self:
			continue
		if not collider is Node2D:
			continue

		var hit_point := forward_shape_cast.get_collision_point(index)
		var distance_on_forward := (hit_point - origin).dot(dir_f)
		hits.append({ "node": collider as Node2D, "distance": distance_on_forward })

	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.distance < b.distance
	)
	for hit in hits:
		var node: Node2D = hit.node
		if node in result:
			continue
		result.append(node)
		if result.size() >= max_count:
			break
	return result


## 是否直面基地。
func is_facing_home() -> bool:
	var home := Eagle.egale_first_grid_pos
	var home_max := home + Vector2i.ONE
	var self_max := grid_pos + grid_size - Vector2i.ONE
	var x_overlap := grid_pos.x <= home_max.x and self_max.x >= home.x
	var y_overlap := grid_pos.y <= home_max.y and self_max.y >= home.y

	match facing:
		Vector2i.LEFT:
			return grid_pos.x > home_max.x and y_overlap
		Vector2i.RIGHT:
			return self_max.x < home.x and y_overlap
		Vector2i.UP:
			return grid_pos.y > home_max.y and x_overlap
		Vector2i.DOWN:
			return self_max.y < home.y and x_overlap
	return false
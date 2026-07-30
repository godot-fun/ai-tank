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
	forward_shape_cast.enabled = true
	forward_shape_cast.exclude_parent = true
	forward_shape_cast.collide_with_areas = true
	forward_shape_cast.collide_with_bodies = true
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


## 开火会打到基地（直面基地、基地前无挡子弹地块、基地前无敌方坦克）。
func is_firing_at_home() -> bool:
	var detect_objects := ray_detect_nearest_objects_in_front()
	for obj in detect_objects:
		if obj is Eagle:
			return true
	return false

func is_aiming_at_enemy() -> bool:
	var detect_objects := ray_detect_nearest_objects_in_front()
	for obj in detect_objects:
		if obj is Enemy:
			return true
	return false



## 用 ShapeCast2D 检测坦克正前方最近的物体。
## 由于扫射有宽度，同层可能命中多个；按前向投影距离取最近 max_count 个（默认 2）。
func ray_detect_nearest_objects_in_front(max_count: int = 2) -> Array[Node2D]:
	var result: Array[Node2D] = []

	var cast_distance := TileConfig.MAP_MAX_DISTANCE
	forward_shape_cast.position = facing
	forward_shape_cast.target_position = facing * cast_distance
	forward_shape_cast.force_shapecast_update()

	var hit_count := forward_shape_cast.get_collision_count()
	if hit_count <= 0:
		return result

	var origin := forward_shape_cast.global_position
	var hits: Array[Dictionary] = []
	for index in range(hit_count):
		var collider := forward_shape_cast.get_collider(index)
		if collider == null or collider == self:
			continue
		if not collider is Node2D:
			continue

		var hit_point := forward_shape_cast.get_collision_point(index)
		var distance_on_forward := (hit_point - origin).dot(facing)
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

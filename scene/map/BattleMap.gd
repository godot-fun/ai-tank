extends Node2D

const SPAWN_INTERVAL := 5.0

@export var show_grid: bool = false

var _target_enemy_count := 0
var _enemies_killed := 0
var _enemies_spawned := 0
var _time_left := 0.0
var _spawn_timer := 0.0
var _battle_active := false

@onready var hud: BattleHud = $BattleHud


func _ready() -> void:
	z_index = -10
	regenerate_map()
	pass


func _process(delta: float) -> void:
	if not _battle_active:
		return

	_time_left -= delta
	_spawn_timer -= delta
	hud.update_timer(_time_left)
	hud.update_enemies_remaining(get_enemies_remaining())

	if _time_left <= 0.0:
		_battle_active = false
		on_time_up()
		return

	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		spawn_enemy_wave()
	pass


func regenerate_map() -> void:
	clear_battlefield()
	_target_enemy_count = BattleProgress.get_enemy_count()
	_enemies_killed = 0
	_enemies_spawned = 0
	_time_left = BattleProgress.get_time_limit()
	_spawn_timer = 0.0
	_battle_active = true

	MapGeneratorHelper.build(self, BattleProgress.level, _target_enemy_count)

	hud.update_enemies_remaining(get_enemies_remaining())
	hud.update_timer(_time_left)
	queue_redraw()
	pass


func clear_battlefield() -> void:
	TileHelper.clear_grid()
	for child in get_children():
		if child is BattleHud:
			continue
		SceneHelper.queue_free(child)
	pass


func get_enemies_remaining() -> int:
	return _target_enemy_count - _enemies_killed


func on_enemy_killed() -> void:
	if not _battle_active:
		return

	_enemies_killed += 1
	hud.update_enemies_remaining(get_enemies_remaining())

	if _enemies_killed >= _target_enemy_count:
		_battle_active = false
		on_level_cleared()
	pass


func spawn_enemy_wave() -> void:
	if _enemies_spawned >= _target_enemy_count:
		return

	for grid in MapGeneratorHelper.get_enemy_spawn_points():
		if _enemies_spawned >= _target_enemy_count:
			break
		if MapGeneratorHelper.try_spawn_enemy_at(grid):
			_enemies_spawned += 1
	pass


func on_level_cleared() -> void:
	Audio.play_sound("res://audio/sfx/level-clear/01.wav")
	BattleProgress.next_level()
	await ThreadUtils.async_sleep(1500)
	regenerate_map()
	pass


func on_time_up() -> void:
	Audio.play_sound("res://audio/sfx/game-over/01.wav")
	await ThreadUtils.async_sleep(2000)
	BattleProgress.start_new_game()
	await SceneHelper.async_change_scene_to_file("res://scene/Main.tscn")
	pass


func _draw() -> void:
	if not show_grid:
		return

	var tile_size := TankConfig.tile_size
	var map_width := TankConfig.map_grid_width * tile_size
	var map_height := TankConfig.map_grid_height * tile_size
	var grid_color := Color(1.0, 1.0, 1.0, 0.25)

	for x in range(TankConfig.map_grid_width + 1):
		var px := x * tile_size
		draw_line(Vector2(px, 0.0), Vector2(px, map_height), grid_color)

	for y in range(TankConfig.map_grid_height + 1):
		var py := y * tile_size
		draw_line(Vector2(0.0, py), Vector2(map_width, py), grid_color)
	pass

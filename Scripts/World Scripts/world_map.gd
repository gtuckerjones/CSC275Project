extends Node2D

@export var noise_height_text: NoiseTexture2D
@onready var ground_tile_map = $World/Layers/ground
@onready var road_tile_map = $World/Layers/roads
@onready var player_scene = preload("res://Scenes/player.tscn")
@onready var player: CharacterBody2D = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var house_scene = preload("res://Scenes/house.tscn")
@onready var tree_scene = preload("res://Scenes/tree.tscn")

var noise: Noise
var map_width = 250
var map_height = 250
var tilemap_source_id = 5
var water_atlas = Vector2i(3, 2)
var ground_atlas = Vector2i(1, 1)
var ground_tiles_arr = []
var ground_tileset_int = 1
var road_tileset_int = 0
var road_tiles_arr = []
var expanded_path = []
var placed_houses = []
var placed_trees = []
var last_y_used = null

func _ready():
	if Global.has_saved_data():
		_load_world_from_global()
	else:
		_generate_world()

func _generate_world():
	print("Generating new world...")

	Global.world_data.seed = randi()
	noise = noise_height_text.noise
	noise.seed = Global.world_data.seed

	_generate_terrain()
	_generate_roads()
	_add_buildings()
	_add_trees()

	_setup_player(Vector2i(0,0))

func _load_world_from_global():
	print("Loading saved world...")
	noise = noise_height_text.noise
	noise.seed = Global.world_data.seed

	_generate_terrain()

	# Roads
	for i in range(Global.world_data.road_points.size()):
		var pair = Global.world_data.road_points[i]
		connect_points_with_roads(pair[0], pair[1])

	# Houses
	for house_pos in Global.world_data.house_positions:
		_spawn_house(house_pos)

	# Trees
	for tree_pos in Global.world_data.tree_positions:
		_spawn_tree(tree_pos)
	
	_setup_player(Global.player_data.last_player_position)

func _generate_terrain():
	ground_tile_map.clear()
	var buffer = 10
	var center_x = map_width / 2.0
	var center_y = map_height / 2.0
	var max_distance = sqrt(center_x * center_x + center_y * center_y)

	for x in range(-center_x, center_x):
		for y in range(-center_y, center_y):
			if abs(x) > center_x - buffer or abs(y) > center_y - buffer:
				ground_tile_map.set_cell(Vector2i(x, y), tilemap_source_id, water_atlas)
				continue

			var val = noise.get_noise_2d(x, y)
			var dist = sqrt(x * x + y * y) / max_distance
			val += 8.0 * pow((1.0 - dist), 1.5) - 3.0

			var pos = Vector2i(x, y)
			if val > 0.0:
				ground_tiles_arr.append(pos)
			else:
				ground_tile_map.set_cell(pos, tilemap_source_id, water_atlas)

	ground_tile_map.set_cells_terrain_connect(ground_tiles_arr, ground_tileset_int, 0, 0)

func _generate_roads():
	var start_positions = []
	var end_positions = []

	for i in range(8):
		var a = get_valid_random_position()
		var b = get_valid_random_position()
		start_positions.append(a)
		end_positions.append(b)
		Global.world_data.road_points.append([a, b])
		connect_points_with_roads(a, b)

func connect_points_with_roads(start: Vector2i, end: Vector2i):
	var path = []
	var current = start
	var horizontal_first = randi() % 2 == 0

	if horizontal_first:
		while current.x != end.x:
			current.x += sign(end.x - current.x)
			if ground_tiles_arr.has(current):
				path.append(current)
		while current.y != end.y:
			current.y += sign(end.y - current.y)
			if ground_tiles_arr.has(current):
				path.append(current)
	else:
		while current.y != end.y:
			current.y += sign(end.y - current.y)
			if ground_tiles_arr.has(current):
				path.append(current)
		while current.x != end.x:
			current.x += sign(end.x - current.x)
			if ground_tiles_arr.has(current):
				path.append(current)

	for pos in path:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var expanded_pos = pos + Vector2i(dx, dy)
				if ground_tiles_arr.has(expanded_pos):
					expanded_path.append(expanded_pos)

	road_tiles_arr += path
	road_tile_map.set_cells_terrain_connect(expanded_path, road_tileset_int, 0, 0)

func _add_buildings():
	var size = Vector2i(10, -14)
	var count = randi_range(8, 12)
	var used = []
	var placed = 0

	while placed < count and used.size() < road_tiles_arr.size():
		var i = randi() % road_tiles_arr.size()
		if used.has(i): continue
		used.append(i)

		var origin = road_tiles_arr[i] + Vector2i(0, -1)
		var spawn_pos = origin - Vector2i(size.x / 2, 0)

		if can_place_building_at(origin, size.x, size.y, placed_houses, 10):
			_spawn_house(origin)
			Global.world_data.house_positions.append(origin)
			placed += 1

func _spawn_house(pos: Vector2i):
	var house = house_scene.instantiate()
	house.set_player_and_camera(player, camera)
	house.position = pos * ground_tile_map.tile_set.tile_size
	add_child(house)

	for x in range(pos.x - 5, pos.x + 5):
		for y in range(pos.y - 14, pos.y):
			placed_houses.append(Vector2i(x, y))

func _add_trees():
	var count = randi_range(30, 60)
	var tries = 0

	while placed_trees.size() < count and tries < count * 50:
		tries += 1
		var tile_pos = ground_tiles_arr[randi() % ground_tiles_arr.size()]
		if tile_pos == Vector2i(0, 0): continue
		if expanded_path.has(tile_pos): continue
		if placed_houses.has(tile_pos): continue

		if placed_trees.any(func(t): return t.distance_to(tile_pos) < 5): continue
		if placed_houses.any(func(h): return h.distance_to(tile_pos) < 3): continue
		if expanded_path.any(func(r): return r.distance_to(tile_pos) < 2): continue

		_spawn_tree(tile_pos)
		Global.world_data.tree_positions.append(tile_pos)

func _spawn_tree(pos: Vector2i):
	var tree = tree_scene.instantiate()
	tree.position = pos * ground_tile_map.tile_set.tile_size
	add_child(tree)
	placed_trees.append(pos)

func _setup_player(pos):
	if not player:
		player = player_scene.instantiate()
	player.position = pos
	camera.zoom = Vector2(2.2, 2.2)

func get_valid_random_position(bias_horizontal := true) -> Vector2i:
	var min_x = -map_width / 2
	var max_x = map_width / 2
	var min_y = -map_height / 2
	var max_y = map_height / 2

	var y = randi_range(min_y, max_y)
	var x = randi_range(min_x, max_x)

	if bias_horizontal and randf() < 0.9:
		y = last_y_used if typeof(last_y_used) == TYPE_INT else y
	else:
		last_y_used = y

	var pos = Vector2i(x, y)
	while not ground_tiles_arr.has(pos):
		x = randi_range(min_x, max_x)
		y = last_y_used if bias_horizontal and typeof(last_y_used) == TYPE_INT and randf() < 0.7 else randi_range(min_y, max_y)
		pos = Vector2i(x, y)

	return pos

func can_place_building_at(origin: Vector2i, width: int, height: int, existing: Array, min_distance: float) -> bool:
	for x in range(origin.x - width / 2, origin.x + width / 2):
		for y in range(origin.y + height, origin.y):
			var pos = Vector2i(x, y)
			if pos == Vector2i(0, 0): return false
			if not ground_tiles_arr.has(pos): return false
			if placed_houses.has(pos): return false
			if road_tile_map.get_cell_source_id(pos) != -1: return false

	var new_center = Vector2(origin.x, origin.y)
	for other in existing:
		if new_center.distance_to(Vector2(other.x, other.y)) < min_distance:
			return false
	return true

func get_player_position() -> Vector2i:
	return $Player.global_position

#Artwork Credits
#All ground, water, and road tiles by Sam Pritchett
#RPG House by Diogo Vernier
#Nature Trees by Admurin

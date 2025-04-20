extends Node2D

@export var noise_height_text : NoiseTexture2D
@onready var ground_tile_map = $ground  # Imports tile_map for generation
@onready var road_tile_map = $roads
var noise : Noise

var map_width : int = 200
var map_height : int = 200
var tilemap_source_id = 5
var water_atlas = Vector2i(3, 2)  # Water tile in the tilemap
var ground_atlas = Vector2i(1, 1)  # Ground tile in the tilemap
var ground_tiles_arr = []
var ground_tileset_int = 1

func generate_world():
	
	ground_tile_map.clear()
	var buffer_size = 10
	var center_x = map_width / 2.0
	var center_y = map_height / 2.0
	var max_distance = sqrt(center_x * center_x + center_y * center_y)
	var falloff_rate = 1.5
	
	for x in range(-center_x, center_x):
		for y in range(-center_y, center_y):
			
			if abs(x) > center_x - buffer_size or abs(y) > center_y - buffer_size:
				ground_tile_map.set_cell(Vector2i(x, y), tilemap_source_id, water_atlas)
				continue  # Skip noise calculation for this tile
			
			var noise_val :float = noise.get_noise_2d(x, y)
			
			var current_distance = sqrt(x * x + y * y) / max_distance
			var normalized_distance = 1.0 - current_distance
			var falloff = 8.0 * pow(normalized_distance, falloff_rate) -3.0
			
			noise_val += falloff
			
			if noise_val > 0.0:
				ground_tiles_arr.append(Vector2i(x,y))
			
			else: 
				ground_tile_map.set_cell(Vector2i(x, y), tilemap_source_id, water_atlas)
			
	ground_tile_map.set_cells_terrain_connect(ground_tiles_arr, ground_tileset_int, 0, 0)

var road_tileset_int = 0

func connect_points_with_roads(start: Vector2i, end: Vector2i):

	var astar = AStar2D.new()
	var road_nodes = {}
	
	var id = 0
	for pos in ground_tiles_arr: 
		astar.add_point(id, pos)
		road_nodes[pos] = id
		id += 1
	
	for pos in ground_tiles_arr:
		var node_id = road_nodes[pos]
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor = pos + offset
			if neighbor in road_nodes:
				astar.connect_points(node_id, road_nodes[neighbor])
	
	if start in road_nodes and end in road_nodes:
		var path = astar.get_point_path(road_nodes[start], road_nodes[end])
		print(path)
		road_tile_map.set_cells_terrain_connect(path, road_tileset_int, 0, 0)

@onready var player_scene = preload("res://Player/player.tscn")  # Path to your Player scene
@onready var player: CharacterBody2D = $Player  # Reference existing player
@onready var camera : Camera2D = $Camera2D  # Reference to the Camera2D node

func setup_player_and_camera():
	if not player:  # Ensure the player isn't already instantiated
		player = player_scene.instantiate()
		add_child(player)  # Add only if it doesn't exist yet

	# Position the player at the center of the map
	player.position = Vector2(0, 0)

	# Set the camera zoom
	camera.zoom = Vector2(2, 2)

	# Make sure the camera follows the player's position
	camera.position = player.position

func _ready():
	noise = noise_height_text.noise  # Get noise from NoiseTexture2D
	noise.seed = randi()  # Randomize the seed for different islands each time
	generate_world()
	
	var start = get_valid_random_position()
	print("Start Position: ", start)
	
	var end = get_valid_random_position()
	print("End Position: ", end)
	
	setup_player_and_camera()
	connect_points_with_roads(start, end)

func _process(delta):
	# Make sure the camera follows the player during the game
	camera.offset = player.position  # Update camera offset to player’s position
	
		# Handle scroll zoom (scrolling up to zoom in, down to zoom out)
	if Input.is_action_pressed("ui_home"):
		camera.zoom -= Vector2(zoom_speed, zoom_speed)  # Zoom in (reduce zoom factor)
	elif Input.is_action_pressed("ui_cut"):
		camera.zoom += Vector2(zoom_speed, zoom_speed)  # Zoom out (increase zoom factor)

var zoom_speed : float = 0.05  # Speed of zooming in/out

func _input(event):
	# Detect scroll input for zooming
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		# Zoom in (scroll up)
		camera.zoom -= Vector2(zoom_speed, zoom_speed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# Zoom out (scroll down)
		camera.zoom += Vector2(zoom_speed, zoom_speed)

func get_valid_random_position() -> Vector2i:
	var pos = Vector2i(randi() % map_width, randi() % map_height)
	
	# Keep generating a new position until it's valid (exists in ground_tiles_arr)
	while not ground_tiles_arr.has(pos):
		pos = Vector2i(randi() % map_width, randi() % map_height)
	
	return pos

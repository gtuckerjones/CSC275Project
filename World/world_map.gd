extends Node2D

@onready var player_scene = preload("res://Player/player.tscn")  # Path to your Player scene
@onready var camera : Camera2D = $Camera2D  # Reference to the Camera2D node
@export var noise_height_text : NoiseTexture2D
@onready var tile_map = $ground  # Imports tile_map for generation
var player : Node2D  # Reference to the player instance
var zoom_speed : float = 0.05  # Speed of zooming in/out

var noise : Noise
var width : int = 500
var height : int = 500
var source_id = 5
var water_atlas = Vector2i(3, 2)  # Water tile in the tilemap
var ground_atlas = Vector2i(1, 1)  # Ground tile in the tilemap

func generate_world():
	tile_map.clear()  # Clears previous tiles before generating a new map
	# Define buffer size (number of water tiles around the edge)
	var buffer_size = 10
	# Calculate the center of the map for radial falloff
	var center_x = width / 2.0
	var center_y = height / 2.0
	var max_distance = sqrt(center_x * center_x + center_y * center_y)  # Max possible distance for falloff
	var land_cutoff = 0.6  # Set max range where land can appear (60% of max distance)
	# Storage for terrain values
	var terrain_map = []
	var land_count = 0
	var total_tiles = width * height
	# **Step 1: Compute Terrain Values First**
	for x in range(-center_x, center_x):
		for y in range(-center_y, center_y):
			# **Force water in the buffer area**
			if abs(x) >= center_x - buffer_size or abs(y) >= center_y - buffer_size:
				terrain_map.append({"pos": Vector2i(x, y), "value": -1})  # Force water
				continue
			# Offset noise generation to center it
			var noise_x = x + center_x
			var noise_y = y + center_y
			# Multi-octave noise for variation
			var noise_val = 0.0
			var frequency = 0.1
			var amplitude = 1.0

			for i in range(3):  # 3 octaves
				noise_val += noise.get_noise_2d(noise_x * frequency, noise_y * frequency) * amplitude
				frequency *= 2
				amplitude *= 0.5
			# Compute radial distance from center
			var distance = sqrt(pow(x, 2) + pow(y, 2)) / max_distance
			# Introduce distortion for organic shape
			var distortion = noise.get_noise_2d(x * 0.75, y * 0.75) * 0.2  # Adjust scale & intensity
			# Apply falloff with distortion (make edges more extreme)
			var falloff = 0.0 if distance > land_cutoff else clamp(1.0 - pow((distance + distortion) / land_cutoff, 10), 0.0, 1.0)
			# Final terrain value
			var final_value = noise_val + falloff
			terrain_map.append({"pos": Vector2i(x, y), "value": final_value})

			if final_value >= 0.2:  # Initial estimate for land
				land_count += 1
	# **Step 2: Adjust Land Threshold to ~70% Coverage**
	var target_land_ratio = 0.7  # Target 70% land coverage
	var current_land_ratio = float(land_count) / total_tiles
	var land_threshold = 0.2  # Default threshold
	if current_land_ratio > target_land_ratio:
		land_threshold += 0.05  # Reduce land
	elif current_land_ratio < target_land_ratio:
		land_threshold -= 0.05  # Increase land
	# **Step 3: Apply the Adjusted Threshold**
	for cell in terrain_map:
		var pos = cell["pos"]
		var value = cell["value"]
		if value == -1:  # Buffer water
			tile_map.set_cell(pos, source_id, water_atlas)
		elif value >= land_threshold:
			tile_map.set_cell(pos, source_id, ground_atlas)  # Land
		else:
			tile_map.set_cell(pos, source_id, water_atlas)  # Water

func setup_player_and_camera():
	# Instantiate the player scene and add it to the main scene
	player = player_scene.instantiate()
	add_child(player)
	
	# Position the player at the center of the map (or any initial position)
	player.position = Vector2(0,0)  # Adjust the starting position as needed
	# Set the camera zoom to 50% (or adjust as needed)
	camera.zoom = Vector2(.2, .2)  # Set the zoom to 50%
	# Position the camera at the player's initial position (optional if not auto-follow)
	camera.position = player.position  # Initially position the camera to player


func _ready():
	noise = noise_height_text.noise  # Get noise from NoiseTexture2D
	noise.seed = randi()  # Randomize the seed for different islands each time
	generate_world()
	setup_player_and_camera()

func _process(delta):
	# Make sure the camera follows the player during the game
	camera.offset = player.position  # Update camera offset to player’s position
	
		# Handle scroll zoom (scrolling up to zoom in, down to zoom out)
	if Input.is_action_pressed("ui_zoom_in"):
		camera.zoom -= Vector2(zoom_speed, zoom_speed)  # Zoom in (reduce zoom factor)
	elif Input.is_action_pressed("ui_zoom_out"):
		camera.zoom += Vector2(zoom_speed, zoom_speed)  # Zoom out (increase zoom factor)

func _input(event):
	# Detect scroll input for zooming
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		# Zoom in (scroll up)
		camera.zoom -= Vector2(zoom_speed, zoom_speed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		# Zoom out (scroll down)
		camera.zoom += Vector2(zoom_speed, zoom_speed)

extends Node2D

@export var noise_height_text : NoiseTexture2D
var noise : Noise

var width : int = 500
var height : int = 500
@onready var tile_map = $ground  # Imports tile_map for generation
@onready var camera = $Camera2D  # Reference to the Camera2D node

var source_id = 5
var water_atlas = Vector2i(3, 2)  # Water tile in the tilemap
var ground_atlas = Vector2i(1, 1)  # Ground tile in the tilemap

func generate_world():
	tile_map.clear()  # Clears previous tiles before generating a new map

	# Define buffer size (number of water tiles around the edge)
	var buffer_size = 10

	# Calculate the center of the map for radial falloff
	var center_x = width / 2
	var center_y = height / 2
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


	# **Step 2: Center the Camera**
	center_camera()

func center_camera():
	# Get the actual tile size
	var tile_size = tile_map.tile_set.tile_size
	# Calculate the correct map center in world coordinates
	var map_center = Vector2(0, 0)  # The center of the generated tiles
	# Convert from tilemap space to world space
	camera.position = tile_map.to_global(map_center)
func _ready():
	noise = noise_height_text.noise  # Get noise from NoiseTexture2D
	noise.seed = randi()  # Randomize the seed for different islands each time
	generate_world()

extends Node2D

@export var noise_height_text: NoiseTexture2D
@onready var ground_tile_map = $World/Layers/ground
@onready var road_tile_map = $World/Layers/roads
@onready var player_scene = preload("res://Scenes/Player/player.tscn")
@onready var player: CharacterBody2D = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var house_scene = preload("res://Scenes/World/house.tscn")
@onready var tree_scene = preload("res://Scenes/World/tree.tscn")
@onready var mob_scene = preload("res://Scenes/Mobs/waechter-20/waechter.tscn")
var survival_time: float = 0.0
@onready var timer_label = $SurvivalTimer/SurvivalTimerLabel
@onready var mob_timer = Timer.new()

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
	setIcons()
	_mobs_timer()
	if Global.has_saved_data():
		_load_world_from_global()
		survival_time = Global.timer
		print("Global Mob Timer", Global.mob_timer)
		mob_timer.wait_time = Global.mob_timer
	else:
		_generate_world()
		mob_timer.wait_time = 5.00
	_start_random_drops_timer()
	
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
	
func _process(delta: float) -> void:
	if $World/Player.is_game_over == false:
		survival_time += delta
		Global.timer = survival_time
		Global.mob_timer = mob_timer.wait_time
		timer_label.text = format_time(survival_time)

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

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
			
	#mj edit
	var front_pos = pos + Vector2i(3.5, 0.5) 
	_spawn_house_guard(front_pos)
	
func _spawn_house_guard(pos: Vector2i):
	print("mob spawned!!!!!!!!!")
	var mob = mob_scene.instantiate()
	mob.position = pos * ground_tile_map.tile_set.tile_size
	add_child(mob)
	#mj close

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
	return player.global_position

func random_drops():
	var max_attempts = 100
	var attempt = 0

	while attempt < max_attempts:
		attempt += 1
		var tile_pos = ground_tiles_arr[randi() % ground_tiles_arr.size()]
		if placed_houses.has(tile_pos): continue
		if placed_trees.has(tile_pos): continue
		if expanded_path.has(tile_pos): continue
		if tile_pos == Vector2i(0, 0): continue

		# Drop table with weights
		var drop_table = [
			{"name": "food", "scene": preload("res://Scenes/Pickups/food.tscn"), "weight": 50},
			{"name": "pistol ammo", "scene": preload("res://Scenes/Pickups/revolver_ammo_pickup.tscn"), "weight": 30},
			{"name": "rifle ammo", "scene": preload("res://Scenes/Pickups/rifle_ammo_pickup.tscn"), "weight": 15},
			{"name": "shotgun ammo", "scene": preload("res://Scenes/Pickups/shotgun_ammo_pickup.tscn"), "weight": 15},
			{"name": "submachine gun ammo", "scene": preload("res://Scenes/Pickups/tommy_ammo_pickup.tscn"), "weight": 30},
			{"name": "rifle", "scene": preload("res://Scenes/Pickups/rifle_pickup.tscn"), "weight": 5},
			{"name": "shotgun", "scene": preload("res://Scenes/Pickups/shotgun_pickup.tscn"), "weight": 5},
			{"name": "tommy gun", "scene": preload("res://Scenes/Pickups/tommygun_pickup.tscn"), "weight": 2}
		]

		var chosen_drop = choose_weighted_drop(drop_table)
		var item = chosen_drop["scene"].instantiate()
		item.position = tile_pos * ground_tile_map.tile_set.tile_size
		add_child(item)
		
		if item.has_signal("pickedupRevolverAmmo"):
			item.connect("pickedupRevolverAmmo", Callable(player, "_on_revolver_ammo_pickup_pickedup_revolver_ammo"))
		elif item.has_signal("pickedupShotgunAmmo"):
			item.connect("pickedupShotgunAmmo", Callable(player, "_on_shotgun_ammo_pickup_pickedup_shotgun_ammo"))
		elif item.has_signal("pickedupRifleAmmo"):
			item.connect("pickedupRifleAmmo", Callable(player, "_on_rifle_ammo_pickup_pickedup_rifle_ammo"))
		elif item.has_signal("pickedupTommyAmmo"):
			item.connect("pickedupTommyAmmo", Callable(player, "_on_tommy_ammo_pickup_pickedup_tommy_ammo"))
		elif item.has_signal("pickedupShotgun"):
			item.connect("pickedupShotgun", Callable(player, "_on_shotgun_pickup_pickedup_shotgun"))
		elif item.has_signal("pickedupRifle"):
			item.connect("pickedupRifle", Callable(player, "_on_rifle_pickup_pickedup_rifle"))
		elif item.has_signal("pickedupTommy"):
			item.connect("pickedupTommy", Callable(player, "_on_tommygun_pickup_pickedup_tommy"))
		elif item.has_signal("pickedUpFood"):
			item.connect("pickedUpFood", Callable(player, "_on_food_picked_up_food"))

		print("Spawned drop: %s at %s" % [chosen_drop["name"], tile_pos])
		return

	print("No valid spot found for a random drop.")

func choose_weighted_drop(drop_table):
	var total_weight = 0
	for item in drop_table:
		total_weight += item["weight"]

	var random_value = randf() * total_weight
	var current = 0

	for item in drop_table:
		current += item["weight"]
		if random_value <= current:
			return item
	return drop_table[0]  # fallback

func _start_random_drops_timer():
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(random_drops)
	add_child(timer)

func random_mob_spawns():
	var max_attempts = 100
	var attempt = 0

	while attempt < max_attempts:
		attempt += 1
		var tile_pos = ground_tiles_arr[randi() % ground_tiles_arr.size()]
		if placed_houses.has(tile_pos): continue
		if placed_trees.has(tile_pos): continue
		if expanded_path.has(tile_pos): continue
		if tile_pos == Vector2i(0, 0): continue

		# Drop table with weights
		var drop_table = [
			{"name": "Spider", "scene": preload("res://Scenes/Mobs/Pixel Spider/Spider.tscn")},
			{"name": "Cocodaemon", "scene": preload("res://Scenes/Mobs/Cacodeaemon/cacodaemon.tscn")}
			]

		var chosen_drop = drop_table[randi() % drop_table.size()]
		var item = chosen_drop["scene"].instantiate()
		item.position = tile_pos * ground_tile_map.tile_set.tile_size
		add_child(item)
		
		print("Spawned mob: %s at %s" % [chosen_drop["name"], tile_pos])
		if mob_timer.wait_time > min_wait_time:
			mob_timer.wait_time = max(mob_timer.wait_time - time_change, min_wait_time)
			print(mob_timer.wait_time)
		return

	print("No valid spot found for a random mob.")
	
	
var min_wait_time = 0.02
var time_change = 0.02

func _mobs_timer():
	#mob_timer.wait_time = 5.00
	mob_timer.autostart = true
	mob_timer.one_shot = false
	mob_timer.timeout.connect(random_mob_spawns)
	add_child(mob_timer)
	
	
#Artwork Credits
#All ground, water, and road tiles by Sam Pritchett
#RPG House by Diogo Vernier
#Nature Trees by Admurin

@onready var revolverIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/RevolverSlot/revolverIcon
@onready var shotgunIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/ShotgunSlot/shotgunIcon
@onready var rifleIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/RifleSlot/rifleIcon
@onready var tommyIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/TommySlot4/tommyIcon

func setIcons():
	revolverIcon.modulate = Color(0, 0, 0, 1)
	shotgunIcon.modulate = Color(0, 0, 0, 1)
	rifleIcon.modulate = Color(0, 0, 0, 1)
	tommyIcon.modulate = Color(0, 0, 0, 1)
	
	
func update_weapon_display():
	if $World/Player.hasRevolver == true:
		revolverIcon.modulate = Color(1, 1, 1, 0.5)
	elif $"World/Player/Ranged Weapons".equipRevolver == true:
		revolverIcon.modulate = Color(1, 1, 1, 1)
		
	if $World/Player.hasShotgun == true:
		shotgunIcon.modulate = Color(1, 1, 1, 0.5)
	elif $"World/Player/Ranged Weapons".equipShotgun == true:
		shotgunIcon.modulate = Color(1, 1, 1, 1)
		
	if $World/Player.hasRifle == true:
		rifleIcon.modulate = Color(1, 1, 1, 0.5)
	elif $"World/Player/Ranged Weapons".equipRifle == true:
		rifleIcon.modulate = Color(1, 1, 1, 1)
		
	if $World/Player.hasTommy == true:
		tommyIcon.modulate = Color(1, 1, 1, 0.5)
	elif $"World/Player/Ranged Weapons".equipTommygun == true:
		tommyIcon.modulate = Color(1, 1, 1, 1)
		
		

func _on_ranged_weapons_ammo_fired(weapon_fired: String, current_amount: int) -> void:
	if weapon_fired == "revolver":
		$World/Player/HUD/VBoxContainer/WeaponDisplay/RevolverSlot/rAmmoAmount.text = str(current_amount)
	elif weapon_fired == "shotgun":
		$World/Player/HUD/VBoxContainer/WeaponDisplay/ShotgunSlot/sAmmoAmount.text = str(current_amount/5)
	elif weapon_fired == "rifle":
		$World/Player/HUD/VBoxContainer/WeaponDisplay/RifleSlot/riAmmoAmount.text = str(current_amount)
	else:
		$World/Player/HUD/VBoxContainer/WeaponDisplay/TommySlot4/tAmmoAmount.text = str(current_amount)


func _on_revolver_pickup_pickedup_gun() -> void:
	update_weapon_display()

func _on_shotgun_pickup_pickedup_shotgun() -> void:
	update_weapon_display()

func _on_rifle_pickup_pickedup_rifle() -> void:
	update_weapon_display()

func _on_tommygun_pickup_pickedup_tommy() -> void:
	update_weapon_display()

func _on_player_switched_weapons() -> void:
	update_weapon_display()
	

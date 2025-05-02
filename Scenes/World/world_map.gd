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
@onready var mob_timer = Timer.new() #timer to spawn mobs after X amount of time

var noise: Noise #randomly produced noise with seed
var map_width = 250 #X and Y for map
var map_height = 250
var tilemap_source_id = 5
var water_atlas = Vector2i(3, 2) #tile location on tilemap
var ground_atlas = Vector2i(1, 1) #tile location on tilemap
var ground_tiles_arr = [] #stored Vector of each ground tile placed
var ground_tileset_int = 1 #tileset number
var road_tileset_int = 0
var road_tiles_arr = [] #stored vector of each road tile
var expanded_path = [] #stored vector of expanded raod tiles
var placed_houses = [] #stored vector of each placed house
var placed_trees = [] #stored vector of each placed tree
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
	var secs = int(seconds) % 60 #formats time correctly
	return "%02d:%02d" % [mins, secs]

func _load_world_from_global():
	print("Loading saved world...")
	noise = noise_height_text.noise
	noise.seed = Global.world_data.seed #retrieves the saved seed and generates the world using the same seed as previously

	_generate_terrain() #generates terrain

	# Roads
	road_tile_map.set_cells_terrain_connect(Global.road_tiles_arr, road_tileset_int, 0, 0)
	#for i in range(Global.world_data.road_points.size()):
		#var pair = Global.world_data.road_points[i] #places roads based on the saved vectors
		#connect_points_with_roads(pair[0], pair[1])

	# Houses
	for house_pos in Global.world_data.house_positions: #places houses based on saved vectors
		_spawn_house(house_pos)

	# Trees
	for tree_pos in Global.world_data.tree_positions: #places trees based on saved vectors
		_spawn_tree(tree_pos)
	
	_setup_player(Global.player_data.last_player_position) #puts the player back at their last position when they left the scene

func _generate_terrain():
	ground_tile_map.clear() #clears the layer in case there's anything on it
	var buffer = 10 #variable for water buffer around the edges of the map, essentially making an island
	var center_x = map_width / 2.0 #finds the center of the map
	var center_y = map_height / 2.0
	var max_distance = sqrt(center_x * center_x + center_y * center_y) #max distance to any corner

	for x in range(-center_x, center_x):
		for y in range(-center_y, center_y): #loops through each tile on the map
			if abs(x) > center_x - buffer or abs(y) > center_y - buffer:
				ground_tile_map.set_cell(Vector2i(x, y), tilemap_source_id, water_atlas) #sets all tiles in the buffer zone to water
				continue

			var val = noise.get_noise_2d(x, y)
			var dist = sqrt(x * x + y * y) / max_distance #distance from center
			val += 8.0 * pow((1.0 - dist), 1.5) - 3.0 #calculates the dropoff rate to ensure that close to center is always land, but towards the outer edges it always drops off to water

			var pos = Vector2i(x, y)
			if val > 0.0:
				ground_tiles_arr.append(pos) #saves the pos to the ground tiles array
			else:
				ground_tile_map.set_cell(pos, tilemap_source_id, water_atlas) #sets pos to water

	ground_tile_map.set_cells_terrain_connect(ground_tiles_arr, ground_tileset_int, 0, 0) #sets every tile in the ground tile array as a ground tile using the ground tileset

func _generate_roads():
	var start_positions = [] # array to hold the start position of each road
	var end_positions = [] # array to hold the end position of each road

	for i in range(8): # creates 8 roads on the map
		var a = get_valid_random_position() #starting point
		var b = get_valid_random_position() #end point
		start_positions.append(a)
		end_positions.append(b)
		Global.world_data.road_points.append([a, b]) #saves the positions to global so they can be used if reloading
		connect_points_with_roads(a, b) #passes points to function to connect the roads together

func connect_points_with_roads(start: Vector2i, end: Vector2i):
	var path = [] #array to hold all the tiles in the raod path
	var current = start
	var horizontal_first = randi() % 2 == 0 #gives a 50/50 chance of the road changing the horizontal values or vertical values first, otherwise all roads would be formed the same way

	if horizontal_first: #loops through all the tiles between start and end point and adds them to the path array
		while current.x != end.x:
			current.x += sign(end.x - current.x)
			if ground_tiles_arr.has(current):
				path.append(current)
		while current.y != end.y:
			current.y += sign(end.y - current.y)
			if ground_tiles_arr.has(current):
				path.append(current)
	else: #same thing but for y values first
		while current.y != end.y:
			current.y += sign(end.y - current.y)
			if ground_tiles_arr.has(current):
				path.append(current)
		while current.x != end.x:
			current.x += sign(end.x - current.x)
			if ground_tiles_arr.has(current):
				path.append(current)

	for pos in path: #expands the path from 1x1 to 3x3 tiles to fit size of the player and monster sprites
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var expanded_pos = pos + Vector2i(dx, dy)
				if ground_tiles_arr.has(expanded_pos):
					expanded_path.append(expanded_pos)

	road_tiles_arr += path #sets all the tiles to the road tiles array for other use
	Global.road_tiles_arr = expanded_path
	road_tile_map.set_cells_terrain_connect(expanded_path, road_tileset_int, 0, 0) #sets every vector to actually be a road tile and uses the road tileset

func _add_buildings():
	var size = Vector2i(10, -14) #size variable that will create a rectangle around the sprite
	var count = randi_range(8, 12) #variable to spawn between 8-12 houses
	var used = [] #array to store used vectors so you don't get houses stacked
	var placed = 0 

	while placed < count and used.size() < road_tiles_arr.size(): #makes sure that you don't place more houses than there are road tiles
		var i = randi() % road_tiles_arr.size() #picks a random vector from the road tiles array to build a house off of
		if used.has(i): 
			continue #skip if vector is already used
		used.append(i) #if not used, save to used

		var origin = road_tiles_arr[i] + Vector2i(0, -1) #adjusts the building origin 1 tile up from the roadf

		if can_place_building_at(origin, size.x, size.y, placed_houses, 10): #passes values to function to make sure that it's valid to build a house there
			_spawn_house(origin) #spawn a house on origin
			Global.world_data.house_positions.append(origin) #save house position for reloads
			placed += 1

func _spawn_house(pos: Vector2i):
	var house = house_scene.instantiate()
	house.position = pos * ground_tile_map.tile_set.tile_size #sets the vector to the size of a whole tile
	add_child(house) #adds house as a child of the main node

	for x in range(pos.x - 5, pos.x + 5):
		for y in range(pos.y - 14, pos.y): #sets all the tiles under the house sprite as invalid tiles for future spawns
			placed_houses.append(Vector2i(x, y))
			
	#mj edit
	var front_pos = pos + Vector2i(3.5, 0.5) #spawns a house guard
	_spawn_house_guard(front_pos)
	
func _spawn_house_guard(pos: Vector2i):
	print("mob spawned!!!!!!!!!")
	var mob = mob_scene.instantiate() #spawns the house guard mob
	mob.position = pos * ground_tile_map.tile_set.tile_size
	add_child(mob)
	#mj close

func _add_trees():
	var count = randi_range(30, 60) #spawns between 30 and 60 trees	
	var tries = 0

	while placed_trees.size() < count and tries < count * 50:
		tries += 1
		var tile_pos = ground_tiles_arr[randi() % ground_tiles_arr.size()]
		if tile_pos == Vector2i(0, 0): continue
		if expanded_path.has(tile_pos): continue #checks to make sure that spaces aren't being used by roads or houses
		if placed_houses.has(tile_pos): continue

		if placed_trees.any(func(t): return t.distance_to(tile_pos) < 5): continue
		if placed_houses.any(func(h): return h.distance_to(tile_pos) < 3): continue  #spaces the trees out from other trees, houses and the roads
		if expanded_path.any(func(r): return r.distance_to(tile_pos) < 2): continue

		_spawn_tree(tile_pos)
		Global.world_data.tree_positions.append(tile_pos) #saves trees to gloval for reloading later

func _spawn_tree(pos: Vector2i):
	var tree = tree_scene.instantiate()
	tree.position = pos * ground_tile_map.tile_set.tile_size #function to instantiate a tree scene at a given location
	add_child(tree)
	placed_trees.append(pos)

func _setup_player(pos):
	if not player:
		player = player_scene.instantiate() #set up player if they don't exist
	player.position = pos
	camera.zoom = Vector2(2.2, 2.2) #sets camera zoom to a reasonable size

func get_valid_random_position(bias_horizontal := true) -> Vector2i:
	var min_x = -map_width / 2
	var max_x = map_width / 2	#mins and maxes for road vectors
	var min_y = -map_height / 2
	var max_y = map_height / 2

	var y = randi_range(min_y, max_y)
	var x = randi_range(min_x, max_x) #pick a random vector

	if bias_horizontal and randf() < 0.9:
		y = last_y_used if typeof(last_y_used) == TYPE_INT else y #had to bias the roads to spawn horizontally by reusing y 90% of the time, in order to make enough space to spawn houses
	else:
		last_y_used = y

	var pos = Vector2i(x, y)
	while not ground_tiles_arr.has(pos): #late while loop to find a valid position if the original y reuse value isn't valid
		x = randi_range(min_x, max_x)
		y = last_y_used if bias_horizontal and typeof(last_y_used) == TYPE_INT and randf() < 0.7 else randi_range(min_y, max_y)
		pos = Vector2i(x, y)

	return pos

func can_place_building_at(origin: Vector2i, width: int, height: int, existing: Array, min_distance: float) -> bool:
	for x in range(origin.x - width / 2, origin.x + width / 2):
		for y in range(origin.y + height, origin.y):
			var pos = Vector2i(x, y)
			if pos == Vector2i(0, 0): return false #don't want houses spawning on player spawn
			if not ground_tiles_arr.has(pos): return false #can't have houses spawn on water
			if placed_houses.has(pos): return false #can't double stack houses
			if road_tile_map.get_cell_source_id(pos) != -1: return false #can't spawn houses on roads

	var new_center = Vector2(origin.x, origin.y)
	for other in existing:
		if new_center.distance_to(Vector2(other.x, other.y)) < min_distance: #checks to make sure houses spawn far enough apart to not have overlapping sprites
			return false
	return true

func get_player_position() -> Vector2i:
	return player.global_position #function to return the player's position

func random_drops():
	var max_attempts = 100
	var attempt = 0

	while attempt < max_attempts: #sets attempts to make sure that items are spawned or the loop is cut after enough failures
		attempt += 1
		var tile_pos = ground_tiles_arr[randi() % ground_tiles_arr.size()]
		if placed_houses.has(tile_pos): continue
		if placed_trees.has(tile_pos): continue #several checks to make sure we have a valid spawn point that doesn't interfere with other items
		if expanded_path.has(tile_pos): continue
		if tile_pos == Vector2i(0, 0): continue

		# Drop table with weights
		var drop_table = [
			{"name": "food", "scene": preload("res://Scenes/Pickups/food.tscn"), "weight": 25},
			{"name": "pistol ammo", "scene": preload("res://Scenes/Pickups/revolver_ammo_pickup.tscn"), "weight": 15},
			{"name": "rifle ammo", "scene": preload("res://Scenes/Pickups/rifle_ammo_pickup.tscn"), "weight": 15},
			{"name": "shotgun ammo", "scene": preload("res://Scenes/Pickups/shotgun_ammo_pickup.tscn"), "weight": 15},
			{"name": "submachine gun ammo", "scene": preload("res://Scenes/Pickups/tommy_ammo_pickup.tscn"), "weight": 15},
			{"name": "rifle", "scene": preload("res://Scenes/Pickups/rifle_pickup.tscn"), "weight": 5},
			{"name": "shotgun", "scene": preload("res://Scenes/Pickups/shotgun_pickup.tscn"), "weight": 5},
			{"name": "tommy gun", "scene": preload("res://Scenes/Pickups/tommygun_pickup.tscn"), "weight": 5}
		]

		var chosen_drop = choose_weighted_drop(drop_table) #chooses a drop from the table based on weight
		var item = chosen_drop["scene"].instantiate() #instantiate
		item.position = tile_pos * ground_tile_map.tile_set.tile_size #assign it's vector to a tile
		add_child(item) #add child to scene
		
		#uses conditionals to set signal connections based on what type of drop is spawned
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
		total_weight += item["weight"] #weights are based out of 100

	var random_value = randf() * total_weight #chooses a random vlue from the weighted values
	var current = 0

	for item in drop_table:
		current += item["weight"]
		if random_value <= current: #adds the weights of items in the drop table until it finds the range the random value falls into
			return item
	return drop_table[0]  # fallback to food if it doesn't work

func _start_random_drops_timer():
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true #timer that calls the random_drops function every 3 seconds and randomly spawns something on the map
	timer.one_shot = false
	timer.timeout.connect(random_drops)
	add_child(timer)

func random_mob_spawns():
	var max_attempts = 100
	var attempt = 0

	while attempt < max_attempts: #able to break loop if spawns repeatedly fail
		attempt += 1
		var tile_pos = ground_tiles_arr[randi() % ground_tiles_arr.size()]
		if placed_houses.has(tile_pos): continue
		if placed_trees.has(tile_pos): continue
		if expanded_path.has(tile_pos): continue #checks to make sure they are being spawned in a valid tile
		if tile_pos == Vector2i(0, 0): continue

		# Drop table with weights
		var drop_table = [ #drop table of spawnable monsters
			{"name": "Spider", "scene": preload("res://Scenes/Mobs/Pixel Spider/Spider.tscn")},
			{"name": "Cocodaemon", "scene": preload("res://Scenes/Mobs/Cacodeaemon/cacodaemon.tscn")}
			]

		var chosen_drop = drop_table[randi() % drop_table.size()]
		var item = chosen_drop["scene"].instantiate()
		item.position = tile_pos * ground_tile_map.tile_set.tile_size #instantiate and add monster to scene
		add_child(item)
		
		print("Spawned mob: %s at %s" % [chosen_drop["name"], tile_pos])
		if mob_timer.wait_time > min_wait_time:
			mob_timer.wait_time = max(mob_timer.wait_time - time_change, min_wait_time) #reduces the mob_timer to make the game progressively harder
			print(mob_timer.wait_time)
		return

	print("No valid spot found for a random mob.")
	
	
var min_wait_time = 0.02
var time_change = 0.02

func _mobs_timer():
	mob_timer.autostart = true
	mob_timer.one_shot = false #mob timer to spawn mobs at a set interval that slowly speeds up after each monster spawned
	mob_timer.timeout.connect(random_mob_spawns)
	add_child(mob_timer)


@onready var revolverIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/RevolverSlot/revolverIcon
@onready var shotgunIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/ShotgunSlot/shotgunIcon
@onready var rifleIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/RifleSlot/rifleIcon
@onready var tommyIcon = $World/Player/HUD/VBoxContainer/WeaponDisplay/TommySlot4/tommyIcon

func setIcons():
	revolverIcon.modulate = Color(0, 0, 0, 1)
	shotgunIcon.modulate = Color(0, 0, 0, 1)
	rifleIcon.modulate = Color(0, 0, 0, 1)
	tommyIcon.modulate = Color(0, 0, 0, 1)
	
	
func update_weapon_display(): #when you switch your weapon using Q or E, it'll highlight the current weapon while fading out the other weapons
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
		
		

func _on_ranged_weapons_ammo_fired(weapon_fired: String, current_amount: int) -> void: #when the specified weapon is fired this lowers the on screen text value that shows your ammo count
	if weapon_fired == "revolver":
		$World/Player/HUD/VBoxContainer/WeaponDisplay/RevolverSlot/rAmmoAmount.text = str(current_amount)
	elif weapon_fired == "shotgun":
		$World/Player/HUD/VBoxContainer/WeaponDisplay/ShotgunSlot/sAmmoAmount.text = str(current_amount/5)
	elif weapon_fired == "rifle":
		$World/Player/HUD/VBoxContainer/WeaponDisplay/RifleSlot/riAmmoAmount.text = str(current_amount)
	else:
		$World/Player/HUD/VBoxContainer/WeaponDisplay/TommySlot4/tAmmoAmount.text = str(current_amount)


#signal functions

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
	

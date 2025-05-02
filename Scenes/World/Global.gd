extends Node

var player_current_attack = false
var playerBody: CharacterBody2D
var timer = 0
var score = 0
var health = 100
var mob_timer = 5.00

var world_data := {
	"seed": null,
	"road_points": [],
	"house_positions": [],
	"tree_positions": []
}

var player_has_revolver = false
var player_has_shotgun = false
var player_has_rifle = false
var player_has_tommy = false
var pistol_ammo = 0
var shotgun_ammo = 0
var rifle_ammo = 0
var tommy_ammo = 0

var player_data := {
	"last_player_position": Vector2i.ZERO,
	"inventory": {
		"revolver": 0,
		"bread": 0,
		"banana": 0,
		"pistol ammo": 0,
		"rifle ammo": 0,
		"shotgun ammo": 0,
		"submachine gun ammo": 0
	}
}

var road_tiles_arr = [
]

# Now this is a full usable loot table

var gun_dictionary = {
	"revolver": {
		"id": "revolver",
		"name": "revolver",
		"texture": preload("res://Spritesheets/mainCharacter/mainCharacter/weapons/revolver.png"),
		"region_rect": get_region_from_coords(1, 0)	
	},
	
	"shotgun": {
		"id": "pistol ammo",
		"name": "Pistol Ammo",
		"texture": preload("res://Spritesheets/mainCharacter/mainCharacter/weapons/revolver.png"),
		"region_rect": get_region_from_coords(1, 2)	
	},
}
var findable_items := {
	"food": {
		"id": "food",
		"name": "Food",
		"description": "Edible, hopefully I feel better",
		"heal": 5,
		"texture": preload("res://Artwork/Tilemap/ProjectUtumno_full.png"),
		"region_rect": get_region_from_coords(40, 1)
	},
	"pistol ammo": {
		"id": "pistol ammo",
		"name": "Pistol Ammo",
		"description": "Shiny bullets, they look like they'll fit in a pistol",
		"damage": 5,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(1, 0)	
	},
	"shotgun ammo": {
		"id": "shotgun ammo",
		"name": "Shotgun Ammo",
		"description": "Filled with heavy pellets, good for multiple targets at once",
		"damage": 10,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(1, 2)
	},
	"rifle ammo": {
		"id": "rifle ammo",
		"name": "Rifle Ammo",
		"description": "Full Metal Jacket, will pack a punch",
		"damage": 20,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(1, 1)
	},
	"submachine gun ammo": {
		"id": "submachine gun ammo",
		"name": "Submachine Gun Ammo",
		"description": "Aim? Never heard of it.",
		"damage": 5,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(2, 1)
	}
}

var food_dictionary = {
	"apple": {
		"id": "apple",
		"name": "Apple",
		"description": "A juicy red apple.",
		"heal": 5,
		"texture": preload("res://Artwork/Tilemap/ProjectUtumno_full.png"),
		"region_rect": get_region_from_coords(40, 1)
	},
	"banana": {
		"id": "banana",
		"name": "Banana",
		"description": "A perfectly ripe banana.",
		"heal": 5,
		"texture": preload("res://Artwork/Tilemap/ProjectUtumno_full.png"),
		"region_rect": get_region_from_coords(40, 4)
	},
	"bread": {
		"id": "bread",
		"name": "Bread",
		"description": "Plain old bread.",
		"heal": 5,
		"texture": preload("res://Artwork/Tilemap/ProjectUtumno_full.png"),
		"region_rect": get_region_from_coords(40, 9)
	}
}

var ammo_dictionary = {
	"pistol ammo": {
		"id": "pistol ammo",
		"name": "Pistol Ammo",
		"description": "Shiny bullets, they look like they'll fit in a pistol",
		"damage": 5,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(1, 0)	
	},
	"shotgun ammo": {
		"id": "shotgun ammo",
		"name": "Shotgun Ammo",
		"description": "Filled with heavy pellets, good for multiple targets at once",
		"damage": 10,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(1, 2)
	},
	"rifle ammo": {
		"id": "rifle ammo",
		"name": "Rifle Ammo",
		"description": "Full Metal Jacket, will pack a punch",
		"damage": 20,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(1, 1)
	},
	"submachine gun ammo": {
		"id": "submachine gun ammo",
		"name": "Submachine Gun Ammo",
		"description": "Aim? Never heard of it.",
		"damage": 5,
		"texture": preload("res://Artwork/Tilemap/2D Pickups v6.2 spritesheet.png"),
		"region_rect": get_region_from_coords(2, 1)
	}

}

func add_item_to_inventory(item_id: String, quantity: int = 1):
	if item_id in player_data["inventory"]:
		player_data["inventory"][item_id] += quantity
	else:
		player_data["inventory"][item_id] = quantity

func remove_item_from_inventory(item_id: String, quantity: int = 1):
	if item_id in player_data["inventory"]:
		player_data["inventory"][item_id] -= quantity
		if player_data["inventory"][item_id] <= 0:
			player_data["inventory"].erase(item_id)

func has_item(item_id: String) -> bool:
	return item_id in player_data["inventory"] and player_data["inventory"][item_id] > 0

func has_saved_data() -> bool:
	return world_data.seed != null
	
func get_region_from_coords(row: int, column: int, tile_size := Vector2(32, 32)) -> Rect2:
	var x = column * tile_size.x
	var y = row * tile_size.y
	return Rect2(x, y, tile_size.x, tile_size.y)

func get_item_data(item_id: String) -> Dictionary:
	if food_dictionary.has(item_id):
		return food_dictionary[item_id]
	elif ammo_dictionary.has(item_id):
		return ammo_dictionary[item_id]
	# You could add other categories here too (weapons, armor, etc)
	else:
		return {}

func reset():
	player_current_attack = false
	timer = 0
	score = 0
	health = 100
	mob_timer = 5.00

	world_data = {
	"seed": null,
	"road_points": [],
	"house_positions": [],
	"tree_positions": []
}

	player_has_revolver = false
	player_has_shotgun = false
	player_has_rifle = false
	player_has_tommy = false
	pistol_ammo = 0
	shotgun_ammo = 0
	rifle_ammo = 0
	tommy_ammo = 0
	
	player_data = {
	"last_player_position": Vector2i.ZERO,
	"inventory": {
		"revolver": 0,
		"bread": 0,
		"banana": 0,
		"pistol ammo": 0,
		"rifle ammo": 0,
		"shotgun ammo": 0,
		"submachine gun ammo": 0
	}
}

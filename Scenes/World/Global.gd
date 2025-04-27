extends Node

var world_data := {
	"seed": null,
	"road_points": [],
	"house_positions": [],
	"tree_positions": []
}

var player_data := {
	"last_player_position": Vector2i.ZERO,
	"inventory": {"apple": 3,
		"bread": 2}
}

var findable_items := {
	"crumpled_note": {"traits": "Handwritten, smudged ink"},
	"rusty_key": {"traits": "Old, corroded, unknown door"},
	"bloodstained_glove": {"traits": "Left-handed, leather"},
	"broken_watch": {"traits": "Stopped at midnight"},
	"mysterious_photograph": {"traits": "Torn edges, unknown faces"},
	"empty_wallet": {"traits": "Monogrammed initials"},
	"silver_locket": {"traits": "Hinged, missing photo"},
	"strange_coin": {"traits": "Foreign markings, worn smooth"},
	"matchbox": {"traits": "Bar logo, one match left"},
	"half-smoked cigar": {"traits": "Distinctive scent, rare brand"},
}

var food_dictionary = {

	"apple": {
		"id": "apple",
		"name": "Apple",
		"description": "A juicy red apple.",
		"heal": 10,
		"texture": preload("res://Artwork/Tilemap/ProjectUtumno_full.png"),
		"region_rect": get_region_from_coords(40, 1)
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

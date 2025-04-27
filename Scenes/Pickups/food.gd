extends Node2D

var food_id : String = ""
var food_name : String = ""
var description : String = ""
var heal_amount : int = 0

@onready var sprite = $Sprite2D

func setup(food_data: Dictionary):
	food_id = food_data.get("id", "")
	food_name = food_data.get("name", "")
	description = food_data.get("description", "")
	heal_amount = food_data.get("heal", 0)
	
	# Set sprite if included in data
	if food_data.has("texture"):
		sprite.texture = food_data["texture"]  # Full spritesheet
		sprite.region_enabled = true
		sprite.region_rect = food_data["region_rect"]  # Rect2(x, y, w, h)

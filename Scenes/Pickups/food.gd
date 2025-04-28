extends Area2D

signal pickedUpFood

var food_id : String = ""
var food_name : String = ""
var description : String = ""
var heal_amount : int = 0

@onready var sprite = $Sprite2D

func _ready():
	# Pick a random food item
	var food_keys = Global.food_dictionary.keys()
	var random_key = food_keys[randi() % food_keys.size()]
	var random_food = Global.food_dictionary[random_key]
	
	# Now set up the food instance
	setup(random_food)

func setup(food_data: Dictionary):
	food_id = food_data.get("id", "")
	food_name = food_data.get("name", "")
	description = food_data.get("description", "")
	heal_amount = food_data.get("heal", 0)
	
	if food_data.has("texture"):
		sprite.texture = food_data["texture"]
		sprite.region_enabled = true
		sprite.region_rect = food_data["region_rect"]

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedUpFood.emit()
		queue_free()

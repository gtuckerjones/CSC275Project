extends Area2D

signal pickedUpFood

var food_id : String = ""
var food_name : String = ""
var description : String = ""

@onready var sprite = $Sprite2D
@onready var player = Global.playerBody


func _ready():
	var food_keys = Global.food_dictionary.keys() #gets a random food item from the food dictionary
	var random_key = food_keys[randi() % food_keys.size()]
	var random_food = Global.food_dictionary[random_key]
	setup(random_food)
	
func setup(food_data: Dictionary):
	if food_data.has("texture"):
		sprite.texture = food_data["texture"] #sets the texture for the instantiated food
		sprite.region_enabled = true
		sprite.region_rect = food_data["region_rect"]
		sprite.scale = Vector2(0.5, 0.5) #scales from 32x32 to 16x16

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player": 
		if player.health < 100:
			pickedUpFood.emit() #emits signal if the player needs food
			queue_free()
		else:
			pass

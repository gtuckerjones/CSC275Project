extends Area2D

signal pickedUpFood

var food_id : String = ""
var food_name : String = ""
var description : String = ""
var heal_amount : int = 0

@onready var sprite = $Sprite2D
@onready var player = Global.playerBody


func _ready():
	# Pick a random food item
	var food_keys = Global.food_dictionary.keys()
	var random_key = food_keys[randi() % food_keys.size()]
	var random_food = Global.food_dictionary[random_key]
	if player:
		print("Player found:", player)
		print("Player script:", player.get_script())
		print("Player health:", player.health)  # Check the script attached to Player
	else:
		print("Player not found!")
	# Now set up the food instance
	setup(random_food)
	
func _process(delta):
	# Check if the player node is still valid
	if player == null:
		player = get_parent().get_node_or_null("World/Player")
		if player:
			print("Player re-found:", player)
			print("Player health:", player.health)

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
		if player.health < 100:
			pickedUpFood.emit()
			queue_free()
		else:
			pass

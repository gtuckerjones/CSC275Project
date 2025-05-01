extends Area2D

@export var object_name: String = "Furniture"
@export var prompt_text: String = "Right click to search"
@export var prompt_node_path: NodePath = "SearchPrompt"
@onready var player = $"../../../Player"

@onready var spawnable_scenes := {
	"food": preload("res://Scenes/Pickups/food.tscn"),
	"pistol ammo": preload("res://Scenes/Pickups/revolver_ammo_pickup.tscn"),
	"shotgun ammo": preload("res://Scenes/Pickups/shotgun_ammo_pickup.tscn"),
	"rifle ammo": preload("res://Scenes/Pickups/rifle_ammo_pickup.tscn"),
	"submachine gun ammo": preload("res://Scenes/Pickups/tommy_ammo_pickup.tscn"),
}

var player_in_range := false
var can_search := true

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player" and can_search:
		player_in_range = true
		show_prompt()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		hide_prompt()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and can_search:
		search_furniture()

func show_prompt():
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.visible = true
		prompt.text = prompt_text + " " + object_name
	else:
		print("Prompt not found at path:", prompt_node_path)

func hide_prompt():
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.visible = false

func search_furniture():
	can_search = false

	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.text = "Searching..."
		prompt.visible = true
		await get_tree().create_timer(3.0).timeout

		var found_item = "Nothing"
		if randf() > 0.25:
			var keys = Global.findable_items.keys()
			var random_key = keys[randi() % keys.size()]
			found_item = random_key
			Global.add_item_to_inventory(found_item, 1)

			# 🪄 Try to instantiate the corresponding scene
			if spawnable_scenes.has(found_item):
				print("Has Item")
				var pickup = spawnable_scenes[found_item].instantiate()
				pickup.position = position + Vector2(193, 319)
				pickup.z_index = 2
				print("Here", get_parent().get_parent())
				get_parent().get_parent().add_child(pickup)
				
				if pickup.has_signal("pickedupRevolverAmmo"):
					pickup.connect("pickedupRevolverAmmo", Callable(player, "_on_revolver_ammo_pickup_pickedup_revolver_ammo"))
				elif pickup.has_signal("pickedupShotgunAmmo"):
					pickup.connect("pickedupShotgunAmmo", Callable(player, "_on_shotgun_ammo_pickup_pickedup_shotgun_ammo"))
				elif pickup.has_signal("pickedupRifleAmmo"):
					pickup.connect("pickedupRifleAmmo", Callable(player, "_on_rifle_ammo_pickup_pickedup_rifle_ammo"))
				elif pickup.has_signal("pickedupTommyAmmo"):
					pickup.connect("pickedupTommyAmmo", Callable(player, "_on_tommy_ammo_pickup_pickedup_tommy_ammo"))
				elif pickup.has_signal("pickedupShotgun"):
					pickup.connect("pickedupShotgun", Callable(player, "_on_shotgun_pickup_pickedup_shotgun"))
				elif pickup.has_signal("pickedupRifle"):
					pickup.connect("pickedupRifle", Callable(player, "_on_rifle_pickup_pickedup_rifle"))
				elif pickup.has_signal("pickedupTommy"):
					pickup.connect("pickedupTommy", Callable(player, "_on_tommygun_pickup_pickedup_tommy"))
				elif pickup.has_signal("pickedUpFood"):
					pickup.connect("pickedUpFood", Callable(player, "_on_food_picked_up_food"))
				
		prompt.text = "Found: " + found_item
		print("Player found:", found_item)

		await get_tree().create_timer(2.0).timeout
		hide_prompt()
		start_search_cooldown()
	else:
		print("Prompt not found at path:", prompt_node_path)

func start_search_cooldown():
	# Wait 2 minutes (120 seconds) before allowing search again
	await get_tree().create_timer(120.0).timeout
	can_search = true

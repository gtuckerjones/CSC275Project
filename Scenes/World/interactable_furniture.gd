extends Area2D

@export var object_name: String = "Furniture"
@export var prompt_text: String = "Press [E] to search"
@export var prompt_node_path: NodePath = "SearchPrompt"

var search_cooldown := false

var player_in_range := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player" and not search_cooldown:
		player_in_range = true
		show_prompt()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		hide_prompt()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not search_cooldown:
		search_furniture()

func show_prompt():
	var prompt = get_node_or_null(prompt_node_path)
	print(prompt_node_path)
	print(prompt)
	if prompt:
		prompt.visible = true
		prompt.text = prompt_text + " " + object_name
	else:
		print("Prompt not found at path:", prompt_node_path)
func hide_prompt():
	var prompt = get_node(prompt_node_path)
	if prompt:
		prompt.visible = false

func search_furniture():
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		search_cooldown = true  # Start cooldown
		prompt.text = "Searching..."
		prompt.visible = true
		await get_tree().create_timer(3.0).timeout  # Wait 3 seconds

		var found_item = "Nothing"
		if randf() > 0.75:  # 25% chance to actually find something
			var keys = Global.findable_items.keys()
			var random_key = keys[randi() % keys.size()]
			found_item = random_key

		prompt.text = "Found: " + found_item
		print("Player found:", found_item)

		# Add the found item to the player's inventory
		if found_item != "Nothing":
			if Global.player_data["inventory"].has(found_item):
				Global.player_data["inventory"][found_item] += 1  # Increase item count
			else:
				Global.player_data["inventory"][found_item] = 1  # Add new item to inventory

		await get_tree().create_timer(2.0).timeout  # Show result for 2 seconds
		hide_prompt()

		# Start 2 minute cooldown
		await get_tree().create_timer(120.0).timeout
		search_cooldown = false
	else:
		print("Prompt not found at path:", prompt_node_path)

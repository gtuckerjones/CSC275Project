extends Area2D

@export var object_name: String = "Furniture"
@export var prompt_text: String = "Press [E] to search"
@export var prompt_node_path: NodePath = "SearchPrompt"

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
	can_search = false  # Disable searching immediately

	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.text = "Searching..."
		prompt.visible = true
		await get_tree().create_timer(3.0).timeout  # Wait 3 seconds

		var found_item = "Nothing"
		if randf() > 0.25:  # 25% chance to find nothing
			var keys = Global.findable_items.keys()
			var random_key = keys[randi() % keys.size()]
			found_item = random_key
			Global.add_item_to_inventory(found_item, 1)

		prompt.text = "Found: " + found_item
		print("Player found:", found_item)

		await get_tree().create_timer(2.0).timeout  # Show result for 2 seconds
		hide_prompt()

		# Now start the cooldown timer (2 minutes)
		start_search_cooldown()
	else:
		print("Prompt not found at path:", prompt_node_path)

func start_search_cooldown():
	# Wait 2 minutes (120 seconds) before allowing search again
	await get_tree().create_timer(120.0).timeout
	can_search = true

extends Area2D

@export var object_name: String = "Furniture"
@export var prompt_text: String = "Press [E] to search"
@export var prompt_node_path: NodePath = "SearchPrompt"
@export var loot_table: Array[String] = ["Key", "Note", "Coins", "Nothing"]
@export var search_label_path: NodePath
@onready var search_label = get_node(search_label_path)

var player_in_range := false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		show_prompt()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		hide_prompt()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
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
	if search_label:
		search_label.text = "Searching..."
		search_label.visible = true
		await get_tree().create_timer(3.0).timeout  # Wait 3 seconds

		var found_item = loot_table[randi() % loot_table.size()]
		search_label.text = "Found: " + found_item
		print("Player found:", found_item)
	else:
		print("Search label not found.")

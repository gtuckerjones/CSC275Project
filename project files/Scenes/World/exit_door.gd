extends Area2D

@export var spawn_position_exterior: Vector2  # Position the player will spawn when exiting
@export var player: NodePath  # Path to the Player node
@export var camera: NodePath  # Path to the Camera node
@export var prompt_text: String = "Right click to exit the house"  # Prompt text for interaction
@export var prompt_node_path: NodePath = "ExitPrompt"  # Path to the prompt label node

var player_in_range := false  # To track if the player is near the exit

func _ready():
	# Connect signals for player entering and exiting the Area2D
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		show_prompt()  # Show the prompt when player is near

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		hide_prompt()  # Hide the prompt when player exits the range

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		# When player presses E, exit the house
		exit_house()

func show_prompt():
	# Show the prompt text when the player is near the exit
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.text = prompt_text  # Set the prompt message
		prompt.visible = true  # Make the prompt visible
	else:
		print("Prompt not found at path:", prompt_node_path)

func hide_prompt():
	# Hide the prompt when the player is no longer near the exit
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.visible = false  # Hide the prompt

func exit_house():
	print("Exit House Triggered")

	# Free the current interior scene
	get_tree().current_scene.queue_free()
	print("Current scene has been queued for free.")
	
	# Load the saved procedural world map from user://
	var packed_scene = load("user://saved_scene.tscn")
	if packed_scene == null or not packed_scene is PackedScene:
		print("Error: Failed to load saved scene at 'user://saved_scene.tscn'")
		return
	
	print("Saved scene loaded successfully.")
	
	# Instantiate the packed scene
	var my_scene = packed_scene.instantiate()
	if my_scene == null:
		print("Error: Failed to instantiate the scene.")
		return
	
	print("Scene instantiated successfully.")
	
	# Add the scene to the root (important so it becomes the active scene)
	get_tree().root.add_child(my_scene)
	print("Instantiated scene added to root.")
	
	# Set the current scene in the SceneTree
	get_tree().current_scene = my_scene
	print("New scene set as current.")

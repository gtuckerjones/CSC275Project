extends Area2D

@export var interior_scene: PackedScene
@export var exit_position_interior: Vector2
@export var return_position_exterior: Vector2
@export var prompt_node_path: NodePath = "EnterPrompt"
@onready var player = $Player
var player_in_range := false
var player_reference: Node = null
var camera_reference: Camera2D = null

func _ready():
	# Connect signals for player entering and exiting the Area2D
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	hide_prompt()

	# Get references to the player and camera nodes
	player_reference = get_node("/root/world_map/Player")  # Adjust path as necessary
	camera_reference = get_node("/root/world_map/Player/Camera2D")  # Adjust path as necessary

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
		enter_building()

func enter_building():
	print("entered building")
	save_world_map_state()
	load_interior_scene()

func save_world_map_state():
	var world_map_scene = get_tree().current_scene  # Current scene (world map)
	var packed_scene = PackedScene.new()
	packed_scene.pack(world_map_scene)
	ResourceSaver.save(packed_scene, "user://saved_scene.tscn")
	
func load_interior_scene():
	if get_tree().current_scene.has_method("get_player_position"):
		print("Triggered")
		Global.player_data.last_player_position = get_tree().current_scene.get_player_position()
	var new_scene = interior_scene.instantiate()
	get_tree().root.add_child(new_scene) 
	get_tree().current_scene.queue_free()
	get_tree().current_scene = new_scene

func show_prompt():
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.visible = true
		prompt.text = "Press [E] to Enter"

func hide_prompt():
	var prompt = get_node_or_null(prompt_node_path)
	if prompt:
		prompt.visible = false

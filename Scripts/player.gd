extends CharacterBody2D

@export var base_speed: int = 200
@export var road_speed_bonus: int = 50
@onready var animations = $AnimationPlayer
@onready var road_tile_map = $"../Layers/roads" # Adjust path to your TileMap

func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if moveDirection.length() > 0:
		moveDirection = moveDirection.normalized()

	var is_on_road = false

	if road_tile_map and is_instance_valid(road_tile_map):
		var current_tile = road_tile_map.local_to_map(global_position)
		var tile_data = road_tile_map.get_cell_tile_data(current_tile)

		if tile_data and tile_data.get_custom_data("is_road"):
			is_on_road = true
	else:
		print_debug("Warning: Road tile map not found or invalid.")

	var effective_speed = base_speed + (road_speed_bonus if is_on_road else 0)
	velocity = moveDirection * effective_speed

func updateAnimation():
	if velocity.length() == 0:
		animations.stop()
	else:
		var direction = "Right"
		if velocity.x < 0:
			direction = "Left"

		animations.play("Walk" + direction)

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()

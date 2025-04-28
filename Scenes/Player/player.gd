extends CharacterBody2D

@export var base_speed: int = 100
@export var road_speed_bonus: int = 50
@onready var animations = $AnimationPlayer
@onready var road_tile_map = $"../Layers/roads" # Adjust path to your TileMap
@onready var rangedWeapons = $"Ranged Weapons"
@onready var sprite = $Sprite2D

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
		var mouse_pos = get_global_mouse_position()
		var mouse_on_right = mouse_pos.x > global_position.x

		if mouse_on_right:
			animations.play("WalkRight")
		else:
			animations.play("WalkLeft")

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()


func _process(delta): 
	var mouse_pos = get_global_mouse_position()
	$Sprite2D.flip_h = mouse_pos.x < global_position.x
	
	if $Sprite2D.flip_h == true:
		$"Ranged Weapons".position.x = -4
	else:
		$"Ranged Weapons".position.x = 4
		
func _on_revolver_pickup_pickedup_gun() -> void:
	$"Ranged Weapons".hasRevolver = true
	$"Ranged Weapons".hasShotgun = false
	$"Ranged Weapons".hasRifle = false
	$"Ranged Weapons".hasTommygun = false

func _on_shotgun_pickup_pickedup_shotgun() -> void:
	$"Ranged Weapons".hasShotgun = true
	$"Ranged Weapons".hasRifle = false
	$"Ranged Weapons".hasTommygun = false
	$"Ranged Weapons".hasRevolver = false

func _on_rifle_pickup_pickedup_rifle() -> void:
	$"Ranged Weapons".hasShotgun = false
	$"Ranged Weapons".hasRifle = true
	$"Ranged Weapons".hasTommygun = false
	$"Ranged Weapons".hasRevolver = false

func _on_tommygun_pickup_pickedup_tommy() -> void:
	$"Ranged Weapons".hasShotgun = false
	$"Ranged Weapons".hasRifle = false
	$"Ranged Weapons".hasTommygun = true
	$"Ranged Weapons".hasRevolver = false

func _on_revolver_ammo_pickup_pickedup_revolver_ammo() -> void:
	var addedAmmo = randi_range(3,8)
	$"Ranged Weapons".revolverAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "revolver", $"Ranged Weapons".revolverAmmo)

func _on_shotgun_ammo_pickup_pickedup_shotgun_ammo() -> void:
	var addedAmmo = randi_range(2,5) * 5
	$"Ranged Weapons".shotgunAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "shotgun", $"Ranged Weapons".shotgunAmmo)

func _on_rifle_ammo_pickup_pickedup_rifle() -> void:
	var addedAmmo = randi_range(2,5)
	$"Ranged Weapons".rifleAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "rifle", $"Ranged Weapons".rifleAmmo)


func _on_tommy_ammo_pickup_pickedup_tommy_ammo() -> void:
	var addedAmmo = randi_range(10,30)
	$"Ranged Weapons".tommyAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "tommy", $"Ranged Weapons".tommyAmmo)
  
func _on_food_picked_up_food() -> void:
	pass # Replace with function body.

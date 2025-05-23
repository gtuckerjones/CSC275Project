extends CharacterBody2D

@export var base_speed: int = 90
@export var road_speed_bonus: int = 50
@onready var animations = $AnimationPlayer
@onready var road_tile_map = $"../Layers/roads" # Adjust path to your TileMap
@onready var rangedWeapons = $"Ranged Weapons"
@onready var sprite = $Sprite2D
#mj edit start
var enemy_inattack_range = false
var enemy_attack_cooldown = true
var health = 100
var max_health = 100
var min_health = 0
#mj edit finish
var player_alive = true
var hasRevolver = false
var hasShotgun = false
var hasRifle = false
var hasTommy = false
#######################################
var available_weapons: Array[String] = []
var current_weapon_idx: int = 0
var equipped_weapon
signal switchedWeapons
var is_game_over = false


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
#mj start edit
func _ready():
	Global.playerBody = self
	$"Ranged Weapons".revolverAmmo = Global.pistol_ammo
	$"Ranged Weapons".shotgunAmmo = Global.shotgun_ammo
	$"Ranged Weapons".rifleAmmo = Global.rifle_ammo
	$"Ranged Weapons".tommyAmmo = Global.tommy_ammo
	$HUD/VBoxContainer/WeaponDisplay/RevolverSlot/rAmmoAmount.text = str($"Ranged Weapons".revolverAmmo)
	$HUD/VBoxContainer/WeaponDisplay/ShotgunSlot/sAmmoAmount.text = str($"Ranged Weapons".shotgunAmmo)
	$HUD/VBoxContainer/WeaponDisplay/RifleSlot/riAmmoAmount.text = str($"Ranged Weapons".rifleAmmo)
	$HUD/VBoxContainer/WeaponDisplay/TommySlot4/tAmmoAmount.text = str($"Ranged Weapons".tommyAmmo)
	
	if Global.player_has_revolver:
		hasRevolver = true
	if Global.player_has_shotgun:
		hasShotgun = true
	if Global.player_has_rifle:
		hasRifle = true
	if Global.player_has_tommy:
		hasTommy = true
	
	if Global.health < 100:
		health = Global.health
#mj end edit



func _physics_process(delta):
	enemy_attack()
	handleInput()
	move_and_slide()
	updateAnimation()
	#mj edit start
	
	
	if health <= 0:
		player_alive = false
		health = 0
		print("player has been killed")
		call_deferred("game_over")
		self.queue_free()
		
#mj edit finish

func _process(delta): 
	var mouse_pos = get_global_mouse_position()
	$Sprite2D.flip_h = mouse_pos.x < global_position.x
	
	if $Sprite2D.flip_h == true:
		$"Ranged Weapons".position.x = -4
	else:
		$"Ranged Weapons".position.x = 4
		
	accessedWeapons()
	
	Global.health = health
	
	Global.pistol_ammo = $"Ranged Weapons".revolverAmmo
	Global.shotgun_ammo = $"Ranged Weapons".shotgunAmmo
	Global.rifle_ammo = $"Ranged Weapons".rifleAmmo
	Global.tommy_ammo = $"Ranged Weapons".tommyAmmo
		
func _on_revolver_pickup_pickedup_gun() -> void:
	hasRevolver = true
	Global.player_has_revolver = true
	$"Ranged Weapons".equipRevolver = true
	$"Ranged Weapons".equipShotgun = false
	$"Ranged Weapons".equipRifle = false
	$"Ranged Weapons".equipTommygun = false

func _on_shotgun_pickup_pickedup_shotgun() -> void:
	hasShotgun = true
	Global.player_has_shotgun = true
	$"Ranged Weapons".equipShotgun = true
	$"Ranged Weapons".equipRifle = false
	$"Ranged Weapons".equipTommygun = false
	$"Ranged Weapons".equipRevolver = false

func _on_rifle_pickup_pickedup_rifle() -> void:
	hasRifle = true
	Global.player_has_rifle = true
	$"Ranged Weapons".equipShotgun = false
	$"Ranged Weapons".equipRifle = true
	$"Ranged Weapons".equipTommygun = false
	$"Ranged Weapons".equipRevolver = false

func _on_tommygun_pickup_pickedup_tommy() -> void:
	hasTommy = true
	Global.player_has_tommy = true
	$"Ranged Weapons".equipShotgun = false
	$"Ranged Weapons".equipRifle = false
	$"Ranged Weapons".equipTommygun = true
	$"Ranged Weapons".equipRevolver = false

func _on_revolver_ammo_pickup_pickedup_revolver_ammo() -> void:
	var addedAmmo = randi_range(3,8)
	$"Ranged Weapons".revolverAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "revolver", $"Ranged Weapons".revolverAmmo)

func _on_shotgun_ammo_pickup_pickedup_shotgun_ammo() -> void:
	var addedAmmo = randi_range(2,5) * 5
	$"Ranged Weapons".shotgunAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "shotgun", $"Ranged Weapons".shotgunAmmo)

func _on_rifle_ammo_pickup_pickedup_rifle_ammo() -> void:
	var addedAmmo = randi_range(2,5)
	$"Ranged Weapons".rifleAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "rifle", $"Ranged Weapons".rifleAmmo)


func _on_tommy_ammo_pickup_pickedup_tommy_ammo() -> void:
	var addedAmmo = randi_range(10,30)
	$"Ranged Weapons".tommyAmmo += addedAmmo
	$"Ranged Weapons".emit_signal("ammo_fired", "tommy", $"Ranged Weapons".tommyAmmo)
	
func accessedWeapons():
	available_weapons.clear()
	
	if hasRevolver:
		available_weapons.append("revolver")
	if hasShotgun:
		available_weapons.append("shotgun")
	if hasRifle:
		available_weapons.append("rifle")
	if hasTommy:
		available_weapons.append("tommy")

	if available_weapons.is_empty():
		return

	if Input.is_action_just_pressed("cycleRight"):
		current_weapon_idx = (current_weapon_idx + 1) % available_weapons.size()
		_equip_weapon(available_weapons[current_weapon_idx])
		switchedWeapons.emit()

	if Input.is_action_just_pressed("cycleLeft"):
		current_weapon_idx = (current_weapon_idx - 1 + available_weapons.size()) % available_weapons.size()
		_equip_weapon(available_weapons[current_weapon_idx])
		switchedWeapons.emit()

func _equip_weapon(weapon: String):
	match weapon:
		"revolver":
			$"Ranged Weapons".equipRevolver = true
			$"Ranged Weapons".equipShotgun = false
			$"Ranged Weapons".equipRifle = false
			$"Ranged Weapons".equipTommygun = false
		"shotgun":
			$"Ranged Weapons".equipRevolver = false
			$"Ranged Weapons".equipShotgun = true
			$"Ranged Weapons".equipRifle = false
			$"Ranged Weapons".equipTommygun = false
		"rifle":
			$"Ranged Weapons".equipRevolver = false
			$"Ranged Weapons".equipShotgun = false
			$"Ranged Weapons".equipRifle = true
			$"Ranged Weapons".equipTommygun = false
		"tommy":
			$"Ranged Weapons".equipRevolver = false
			$"Ranged Weapons".equipShotgun = false
			$"Ranged Weapons".equipRifle = false
			$"Ranged Weapons".equipTommygun = true
		_:
			print("Unknown weapon: ", weapon)

#mj edit start
func player():
	pass

func _on_player_hitbox_body_entered(body: Node2D):
	if body.has_method("enemy"):
		enemy_inattack_range = true

func _on_player_hitbox_body_exited(body: Node2D):
	if body.has_method("enemy"):
		enemy_inattack_range = false
		
		
func enemy_attack():
	if enemy_inattack_range == true and enemy_attack_cooldown == true:
		health = health - 20
		enemy_attack_cooldown = false
		$attack_cooldown.start()
		print(health)
		

func _on_attack_cooldown_timeout():
	enemy_attack_cooldown = true
	
func game_over():
	is_game_over = true
	get_tree().change_scene_to_file("res://Scenes/Title and Death Screen/GameOver.tscn")
	
	
func apply_poison_damage():
	if health > 0:
		health -= 10  # Or whatever damage value
		print("Poisoned! Health now:", health)
#mj edit finish

  
func _on_food_picked_up_food() -> void:
	if health < max_health:
		health += randi_range(5, 25)
		$HUD/VBoxContainer/WeaponDisplay/RevolverSlot/rAmmoAmount

func _on_ranged_weapons_ammo_fired(weapon_fired: String, current_amount: int) -> void:
	if weapon_fired == "revolver":
		$HUD/VBoxContainer/WeaponDisplay/RevolverSlot/rAmmoAmount.text = str(current_amount)
	elif weapon_fired == "shotgun":
		$HUD/VBoxContainer/WeaponDisplay/ShotgunSlot/sAmmoAmount.text = str(current_amount/5)
	elif weapon_fired == "rifle":
		$HUD/VBoxContainer/WeaponDisplay/RifleSlot/riAmmoAmount.text = str(current_amount)
	else:
		$HUD/VBoxContainer/WeaponDisplay/TommySlot4/tAmmoAmount.text = str(current_amount)

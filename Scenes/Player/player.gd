extends CharacterBody2D

@export var speed: int = 100
@onready var animations = $AnimationPlayer
@onready var rangedWeapons = $RangedWeapons
@onready var sprite = $Sprite2D
var weapons_inventory: Array = []
var current_weapon: String = ""

func pickup_weapon(weapon_name: String):
	if weapon_name not in weapons_inventory:
		weapons_inventory.append(weapon_name)
	current_weapon = weapon_name
	rangedWeapons.current_weapon = weapon_name
	rangedWeapons.selectedGun()

func switch_weapon():
	if weapons_inventory.size() > 0:
		var current_index = weapons_inventory.find(current_weapon)
		var next_index = (current_index + 1) % weapons_inventory.size()
		current_weapon = weapons_inventory[next_index]
		rangedWeapons.current_weapon = current_weapon
		rangedWeapons.selectedGun()

func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if moveDirection.length() > 0:
		moveDirection = moveDirection.normalized()  # Normalize to prevent diagonal speed boost
	velocity = moveDirection * speed

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
	
	if Input.is_action_just_pressed("switch_weapon"):
		switch_weapon()
	
	if has_node("rangedWeapons"):
		var weapon = $RangedWeapons
		var offset_x = 5
		weapon.position.x = -offset_x if $Sprite2D.flip_h else offset_x

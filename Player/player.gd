extends CharacterBody2D

@export var speed: int = 200
@onready var animations = $AnimationPlayer
var facing_left = false  
@export var weapon_scene: PackedScene 
var weapon

func _ready():
	weapon = weapon_scene.instantiate()
	add_child(weapon)

func equip_weapon(new_weapon: String):
	if weapon:
		weapon.equipped_weapon = new_weapon
		weapon.update_weapon_sprite()
		weapon.update_weapon_collision()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if weapon:
			weapon.attack()

func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = moveDirection * speed

	if velocity.x < 0:
		facing_left = true
	elif velocity.x > 0:
		facing_left = false

func updateAnimation():
	if velocity.length() == 0:
		animations.stop()
	else:
		if facing_left:
			animations.play("WalkLeft")
		else:
			animations.play("WalkRight")

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()

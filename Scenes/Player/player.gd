extends CharacterBody2D

@export var speed: int = 100
@onready var animations = $AnimationPlayer
@onready var rangedWeapons = $Ranged_Weapons
@onready var sprite = $Sprite2D

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
	
	if $Sprite2D.flip_h == true:
		$"Ranged Weapons".position.x = -4
	else:
		$"Ranged Weapons".position.x = 4
		
func _on_revolver_pickup_pickedup_gun() -> void:
	$"Ranged Weapons".hasRevolver = true

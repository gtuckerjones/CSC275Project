extends CharacterBody2D

@export var speed: int = 200
@onready var animations = $AnimationPlayer
var facing_left = false  

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

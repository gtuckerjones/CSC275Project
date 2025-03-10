extends CharacterBody2D

@export var speed: int = 200
@onready var animations = $AnimationPlayer

func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = moveDirection*speed

func updateAnimation():
	if velocity.length() == 0:
		animations.stop()
	else:
		var Direction = "Right"
		if velocity.x < 0: Direction = "Left"
		elif velocity.y > 0: Direction = "Down"
		elif velocity.y < 0: Direction = "Up"
		
		if (Direction == "Up" or "Down") and (velocity.x < 0):
			animations.play("WalkLeft")
		else:
			animations.play("WalkRight") 

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()

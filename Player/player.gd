extends CharacterBody2D

@export var speed: int = 200
@onready var animations = $AnimationPlayer

func handleInput():
	var moveDirection = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if moveDirection.length() > 0:
		moveDirection = moveDirection.normalized()  # Normalize to prevent diagonal speed boost
	velocity = moveDirection * speed

func updateAnimation():
	if velocity.length() == 0:
		animations.stop()
	else:
		var direction = "Right"
		if velocity.x < 0:
			direction = "Left"
		elif abs(velocity.x) < abs(velocity.y):  
			direction = "Up" if velocity.y < 0 else "Down"

		animations.play("Walk" + direction)

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()

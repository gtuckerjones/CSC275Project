extends CharacterBody2D

var speed = 20
var dir: Vector2

var is_spider_chase: bool

var player: CharacterBody2D
var health = 100
var max_health = 100
var min_health = 0

func _ready():
	is_spider_chase = true
	
func _process(delta):
	move(delta)
	handle_animation()

func _on_timer_timeout() -> void:
	$Timer.wait_time = choose([0.5, 0.8])
	if !is_spider_chase:
		dir = choose([Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN])
		print(dir)
		
func move(delta):
	if is_spider_chase:
		player = Global.playerBody
		if is_instance_valid(player):
			velocity = position.direction_to(player.position) * speed
			dir.x = abs(velocity.x)/velocity.x
	elif !is_spider_chase:
		velocity += dir * speed * delta
	move_and_slide()
	
func choose(array):
	array.shuffle()
	return array.front()
	
func handle_animation():
	$AnimatedSprite2D.play("walk")
	if dir.x == -1:
		$AnimatedSprite2D.flip_h = true
	elif dir.x == 1:
		$AnimatedSprite2D.flip_h = false
		
func enemy():
	pass

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		self.queue_free()

#Script worked on by Megan
#Credit to DevWorm for major outline

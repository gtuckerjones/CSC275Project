extends Area2D

const SPEED: int = 2000
var max_distance: float = 200.0
var traveled_distance: float = 0.0
var health = 100

func _process(delta: float) -> void:
	var movement = transform.x * SPEED * delta
	position += movement
	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		queue_free()
		
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()



func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enemy"): # make sure enemies are in the "enemy" group!
		if body.has_method("take_damage"):
			body.take_damage(50) # or whatever damage amount you want
		queue_free() # Destroy the bullet when it hits
		

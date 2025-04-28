extends CharacterBody2D


var speed = 55
var player_chase = false
var player = null

func _physics_process(delta):
	if player_chase:
		if position.distance_to(player.position) > 10:
			position+=(player.position-position)/speed
			$AnimatedSprite2D.play("attack")
			#move_and_collide(Vector2(0,0))
		
			if(player.position.x - position.x) < 0:
				$AnimatedSprite2D.flip_h = true
			else:
				$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.play("idle")
	move_and_slide()
	

func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase = true
	


func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase = false

extends CharacterBody2D

var is_puffing = false


func _process(delta):
	if $AnimatedSprite2D.animation == "puff" and $AnimatedSprite2D.is_playing():
		$PoisonHitbox/CollisionShape2D.disabled = false 
	else:
		$PoisonHitbox/CollisionShape2D.disabled = true


func _on_puff_timer_timeout() -> void:
	if is_puffing:
		$AnimatedSprite2D.play("idle")
	else:
		$AnimatedSprite2D.play("puff")
	is_puffing = !is_puffing
	

func _on_poison_hitbox_body_entered(body: Node2D) -> void:
	if $AnimatedSprite2D.animation == "puff":
		print("in hitbox")
		if body.has_method("apply_poison_damage"):
			body.apply_poison_damage()
		elif body.get_parent().has_method("apply_poison_damage"):
			body.get_parent().apply_poison_damage()

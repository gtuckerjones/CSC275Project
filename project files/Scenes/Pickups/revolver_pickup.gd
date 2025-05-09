extends Area2D

signal pickedupGun

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupGun.emit()
		queue_free()

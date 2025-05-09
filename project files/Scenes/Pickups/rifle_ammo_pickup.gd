extends Area2D

signal pickedupRifleAmmo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupRifleAmmo.emit()
		queue_free()

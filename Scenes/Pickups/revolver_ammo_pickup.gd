extends Area2D

signal pickedupRevolverAmmo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupRevolverAmmo.emit()
		queue_free()

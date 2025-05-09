extends Area2D

signal pickedupRifle

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupRifle.emit()
		queue_free()

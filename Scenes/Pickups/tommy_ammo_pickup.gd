extends Area2D

signal pickedupTommyAmmo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupTommyAmmo.emit()
		queue_free()

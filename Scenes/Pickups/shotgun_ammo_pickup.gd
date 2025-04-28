extends Area2D

signal pickedupShotgunAmmo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupShotgunAmmo.emit()
		queue_free()

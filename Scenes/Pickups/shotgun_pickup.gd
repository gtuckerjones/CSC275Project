extends Area2D

signal pickedupShotgun

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		pickedupShotgun.emit()
		queue_free()

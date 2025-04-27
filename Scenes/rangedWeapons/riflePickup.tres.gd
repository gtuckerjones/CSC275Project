extends Area2D

@export var weapon_name: String = "rifle"

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.pickup_weapon(weapon_name)
		queue_free()

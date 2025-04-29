extends RigidBody2D

var health = 100
var max_health = 100
var min_health = 0

func _process(delta: float) -> void:
	$AnimatedSprite2D.play("puff")

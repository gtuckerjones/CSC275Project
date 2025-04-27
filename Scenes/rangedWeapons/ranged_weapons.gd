extends Node2D

const BULLET = preload("res://Scenes/Bullet/bullet.tscn")
@onready var muzzle: Marker2D = $Marker2D
@onready var revolver = $Revolver
@onready var shotgun = $Shotgun
@onready var rifle = $Rifle
@onready var tommygun = $Tommygun
var current_weapon = ""

func selectedGun():
	revolver.visible = current_weapon == "revolver"
	shotgun.visible = current_weapon == "shotgun"
	rifle.visible = current_weapon == "rifle"
	tommygun.visible = current_weapon == "tommygun"

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -.25
	else:
		scale.y = .25
		
	selectedGun()
		
	if Input.is_action_just_pressed("fire"):
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation

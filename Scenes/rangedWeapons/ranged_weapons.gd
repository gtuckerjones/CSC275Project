extends Node2D

const BULLET = preload("res://Scenes/Bullet/bullet.tscn")
@onready var muzzle: Marker2D = $Marker2D
var hasRevolver = false
var hasShotgun = false
var hasRifle = false
var hasTommygun = false

func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -.25
	else:
		scale.y = .25
		
	if hasRevolver == true:
		$Revolver.visible = true
		$Shotgun.visible = false
		$Rifle.visible = false
		$Tommygun.visible = false
		
		if Input.is_action_just_pressed("fire"):
			var bullet_instance = BULLET.instantiate()
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation
			
	if hasShotgun == true:
		$Revolver.visible = false
		$Shotgun.visible = true
		$Rifle.visible = false
		$Tommygun.visible = false
		
		if Input.is_action_just_pressed("fire"):
			var bullet_instance = BULLET.instantiate()
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation
			
	if hasRifle == true:
		$Revolver.visible = false
		$Shotgun.visible = false
		$Rifle.visible = true
		$Tommygun.visible = false
		
		if Input.is_action_just_pressed("fire"):
			var bullet_instance = BULLET.instantiate()
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation
			
	if hasTommygun == true:
		$Revolver.visible = false
		$Shotgun.visible = false
		$Rifle.visible = false
		$Tommygun.visible = true
		
		if Input.is_action_just_pressed("fire"):
			var bullet_instance = BULLET.instantiate()
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation

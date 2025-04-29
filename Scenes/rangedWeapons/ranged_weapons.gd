extends Node2D

const  BULLET = preload("res://Scenes/Bullet/bullet.tscn")
@onready var muzzle: Marker2D = $Marker2D
var equipRevolver = false
var equipShotgun = false
var equipRifle = false
var equipTommygun = false
var revolverDamage = randi_range(15,30)
var shotgunDamage = randi_range(10,20)
var rifleDamage = randi_range(30,70)
var tommyDamage = randi_range(5,10)
var fire_cooldown = 0.0
var fire_rate = 0.1 
var revolverAmmo = 0
var shotgunAmmo = 0
var rifleAmmo = 0
var tommyAmmo = 0
signal ammo_fired(weapon_fired: String, current_amount: int)


func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	fire_cooldown -= delta
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -.25
	else:
		scale.y = .25
		
	if equipRevolver == true:
		$Revolver.visible = true
		$Shotgun.visible = false
		$Rifle.visible = false
		$Tommygun.visible = false
		fire_rate = 0.25
		
		
		if Input.is_action_just_pressed("fire") and fire_cooldown <= 0.0 and revolverAmmo > 0:
			var bullet_instance = BULLET.instantiate()
			bullet_instance.damage = revolverDamage
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation
			bullet_instance.max_distance = 300
			fire_cooldown = fire_rate
			revolverAmmo -= 1
			emit_signal("ammo_fired", "revolver", revolverAmmo)
			damageGiven.emit(revolverDamage)
			
			
			
	if equipShotgun == true:
		$Revolver.visible = false
		$Shotgun.visible = true
		$Rifle.visible = false
		$Tommygun.visible = false
		fire_rate = 0.5
		
		
		if Input.is_action_just_pressed("fire") and fire_cooldown <= 0.0 and shotgunAmmo > 0:
			var spread_num = 5
			var spread_degrees = 30
			
			for i in range(spread_num):
				var bullet_instance = BULLET.instantiate()
				bullet_instance.damage = shotgunDamage
				get_tree().root.add_child(bullet_instance)
				bullet_instance.global_position = muzzle.global_position
				var spread = deg_to_rad(randf_range(-spread_degrees/2, spread_degrees/2))
				bullet_instance.rotation = rotation + spread
				bullet_instance.max_distance = 75.0
				fire_cooldown = fire_rate
				shotgunAmmo -= 1
				emit_signal("ammo_fired", "shotgun", shotgunAmmo)
			
	if equipRifle == true:
		$Revolver.visible = false
		$Shotgun.visible = false
		$Rifle.visible = true
		$Tommygun.visible = false
		fire_rate = 0.8
		
		
		if Input.is_action_just_pressed("fire") and fire_cooldown <= 0.0 and rifleAmmo > 0:
			var bullet_instance = BULLET.instantiate()
			bullet_instance.damage = rifleDamage
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation
			bullet_instance.max_distance = 500
			fire_cooldown = fire_rate
			rifleAmmo -= 1 
			emit_signal("ammo_fired", "rifle", rifleAmmo)
			
			
	if equipTommygun == true:
		$Revolver.visible = false
		$Shotgun.visible = false
		$Rifle.visible = false
		$Tommygun.visible = true
		fire_rate = 0.1
		
		
		if Input.is_action_pressed("fire") and fire_cooldown <= 0.0 and tommyAmmo > 0:
			var bullet_instance = BULLET.instantiate()
			bullet_instance.damage = tommyDamage
			get_tree().root.add_child(bullet_instance)
			bullet_instance.global_position = muzzle.global_position
			bullet_instance.rotation = rotation
			bullet_instance.max_distance = 200
			fire_cooldown = fire_rate
			tommyAmmo -= 1
			emit_signal("ammo_fired", "tommy", tommyAmmo)
			

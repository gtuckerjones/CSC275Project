extends CanvasLayer

@onready var weapon_label = $CurrentWeaponLabel

func set_weapon_name(weapon_name: String):
	weapon_label.text = "Current Weapon: " + weapon_name

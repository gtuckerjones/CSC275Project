extends Control

@onready var grid_container = $NinePatchRect/GridContainer
@onready var vbox_container = $PopupPanel/VBoxContainer

var is_open = false

func _ready():
	print("Initialized Inventory")
	close()
	$PopupPanel.visible = false
	
func _process(delta):
	_update_inventory_ui()
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()
			
func open():
	self.visible = true
	is_open = true

func close():
	visible = false
	is_open = false
	
func _on_slot_mouse_entered(item_id):
	var item_data = Global.food_dictionary.get(item_id, {})
	show_item_details(item_data)
	
func _update_inventory_ui():
	var inventory = Global.player_data["inventory"]
	var item_keys = inventory.keys()
	var slots = grid_container.get_children()

	for i in range(slots.size()):
		var slot = slots[i]
		var icon = slot.get_node("Icon")
		var quantity_label = slot.get_node("QuantityLabel")

		if i < item_keys.size():
			var item_id = item_keys[i]
			var item_data = Global.food_dictionary.get(item_id, {})
			var atlas = item_data.get("texture", null)  # Full atlas texture
			var region = item_data.get("region_rect", Rect2())

			if atlas:
				var atlas_texture := AtlasTexture.new()
				atlas_texture.atlas = atlas
				atlas_texture.region = region
				icon.texture = atlas_texture  # Override the default slot texture
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.expand = true
			else:
				icon.texture = icon.texture  # Keep default if missing atlas (optional line)

			quantity_label.text = "x%d" % inventory[item_id]
			slot.visible = true
		else:
			# Keep default slot texture, just clear quantity and hide
			quantity_label.text = ""
			slot.visible = true  # Or false if you want to hide unused slots

func show_item_details(item_data):
	vbox_container.clear()  # (you can remove all children manually if needed)

	var name_label = Label.new()
	name_label.text = item_data.get("name", "Unknown Item")
	vbox_container.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "No description")
	vbox_container.add_child(desc_label)

	if item_data.has("heal"):
		var heal_label = Label.new()
		heal_label.text = "Heal: %d HP" % item_data["heal"]
		vbox_container.add_child(heal_label)

	if item_data.has("damage"):
		var damage_label = Label.new()
		damage_label.text = "Damage: %d" % item_data["damage"]
		vbox_container.add_child(damage_label)

	if item_data.has("armor"):
		var armor_label = Label.new()
		armor_label.text = "Armor: %d" % item_data["armor"]
		vbox_container.add_child(armor_label)
		
	$PopupPanel.visible = true

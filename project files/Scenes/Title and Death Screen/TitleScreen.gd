extends Control

@onready var texture_rect = $TextureRect
@onready var color_rect = $ColorRect
@onready var buttonLabel = $PlayGame
@onready var music = $AudioStreamPlayer2D

var pitch_direction := 1  # 1 = increasing, -1 = decreasing
var pitch_timer := 0.0

func _ready():
	pass
	#update_texture_size()

func _process(delta):
	pitch_timer += delta
	if pitch_timer >= 1.0:
		pitch_timer = 0.0  # Reset timer every second
		
		music.pitch_scale += 0.01 * pitch_direction

		# Check bounds and reverse direction
		if music.pitch_scale >= 4.0:
			music.pitch_scale = 4.0
			pitch_direction = -1
		elif music.pitch_scale <= 1.0:
			music.pitch_scale = 1.0
			pitch_direction = 1


func update_texture_size():
	var viewport_width = get_viewport().size.x
	var viewport_height = get_viewport().size.y
	var texture = $TextureRect.texture
	if texture:
		var texture_width = texture.get_width()
		var texture_height = texture.get_height()
		var scale = min(viewport_width / texture_width, viewport_height / texture_height)
		set_size(Vector2(texture_width * scale, texture_height * scale))
		set_position(Vector2((viewport_width - texture_width * scale) / 2, (viewport_height - texture_height * scale) / 2))

func _on_play_game_pressed() -> void:
	buttonLabel.text = "Loading..."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/World/world_map.tscn")
	
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Title and Death Screen/Credits.tscn")
	
func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Title and Death Screen/howToPlay.tscn")
	
func _on_quit_pressed() -> void:
	get_tree().quit()

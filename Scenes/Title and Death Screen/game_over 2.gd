extends Control

@onready var buttonLabel = $PlayGame

func _on_play_game_pressed() -> void:
	buttonLabel.text = "Loading..."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/World/world_map.tscn")


#Created by Megan and Sam

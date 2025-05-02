extends Control

@onready var buttonLabel = $PlayGame
@onready var time_survived = $SurvivalTimer/TimeSurvived
@onready var score = $SurvivalTimer/Score

func _ready() -> void:
	
	var total_seconds = int(Global.timer)
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60 #Converts the saved score variable to standard time
	time_survived.text = "%02d:%02d" % [minutes, seconds]
	score.text = str(Global.score)

func _on_play_game_pressed() -> void:
	buttonLabel.text = "Loading..."
	Global.reset()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/World/world_map.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()


#Created by Megan and Sam

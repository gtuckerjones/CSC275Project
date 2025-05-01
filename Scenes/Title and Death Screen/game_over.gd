extends Control

@onready var buttonLabel = $PlayGame

func _ready():
	$SurvivalTimer/SurvivalTimerLabel.text = format_time(Global.timer)
	$VBoxContainer/scoreAmount.text = str(Global.score)
	
func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]
	

func _on_play_game_pressed() -> void:
	buttonLabel.text = "Loading..."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/World/world_map.tscn")


#Created by Megan and Sam
#Image by Rochak Shukla on Freepik

func _on_button_pressed() -> void:
	print("quit")
	get_tree().quit()

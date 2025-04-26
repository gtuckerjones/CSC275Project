# PlayerCameraSingleton.gd
extends Node

var player_reference: Node = null
var camera_reference: Camera2D = null

# Function to set player and camera references
func set_player_and_camera(player_node: Node, camera_node: Camera2D):
	player_reference = player_node
	camera_reference = camera_node

# Function to get player and camera references
func get_player_and_camera() -> Dictionary:
	return {"player": player_reference, "camera": camera_reference}

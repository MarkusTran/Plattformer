extends Node2D

@export var connected_scene: String

var scene_folder = "res://Levels/"

func _add_a_scene_manually():
	# This is like autoloading the scene, only
	# it happens after already loading the main scene.
	
	var full_path = scene_folder +connected_scene + ".tscn"
	var scene_tree = get_tree()
	scene_tree.change_scene_to_file(full_path)

func interact(player):
	_add_a_scene_manually()

extends Control


func _on_back_to_start_pressed() -> void:
	Global.finished_level = 1
	get_tree().change_scene_to_file("res://UI/title_screen.tscn")

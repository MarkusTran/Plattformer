extends Control


func _on_start_pressed():
	get_tree().change_scene_to_file("res://Levels/level_1.tscn")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://Levels/ShopMenu.tscn")

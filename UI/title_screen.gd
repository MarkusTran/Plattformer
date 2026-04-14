extends Control


@onready var main_panel: BoxContainer = $Main
@onready var ControlsPanel: Panel = $ControlsPanel
@onready var SettingsPanel: Panel = $SettingsPanel

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Levels/level_1.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
	


func _on_options_pressed() -> void:
	main_panel.hide()
	ControlsPanel.show()
	SettingsPanel.show()
	
func _on_back_pressed() -> void:
	main_panel.show()
	ControlsPanel.hide()
	SettingsPanel.hide()

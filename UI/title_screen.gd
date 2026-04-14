extends Control


@onready var main_panel: BoxContainer = $Main
@onready var ControlsPanel: Panel = $ControlsPanel
@onready var SettingsPanel: Panel = $SettingsPanel
@onready var music_sound: AudioStreamPlayer = get_node_or_null("Music")


func _ready() -> void:
	if Global.audio_settings_changed.is_connected(_apply_audio_settings) == false:
		Global.audio_settings_changed.connect(_apply_audio_settings)
	if music_sound != null and music_sound.finished.is_connected(_on_music_finished) == false:
		music_sound.finished.connect(_on_music_finished)
	_apply_audio_settings()
	if music_sound != null and not music_sound.playing:
		music_sound.play()


func _apply_audio_settings() -> void:
	if music_sound != null:
		music_sound.volume_db = Global.get_music_volume_db()


func _on_music_finished() -> void:
	if music_sound != null:
		music_sound.play()


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

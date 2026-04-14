extends Control


@onready var winning_sound: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")


func _ready() -> void:
	if Global.audio_settings_changed.is_connected(_apply_audio_settings) == false:
		Global.audio_settings_changed.connect(_apply_audio_settings)
	_apply_audio_settings()


func _apply_audio_settings() -> void:
	if winning_sound != null:
		winning_sound.volume_db = Global.get_music_volume_db()


func _on_back_to_start_pressed() -> void:
	Global.finished_level = 1
	get_tree().change_scene_to_file("res://UI/title_screen.tscn")

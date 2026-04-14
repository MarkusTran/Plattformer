extends Node

signal audio_settings_changed
signal display_settings_changed
signal boss_music_changed(is_boss: bool)

const SETTINGS_FILE := "user://settings.cfg"

var playerBody: CharacterBody2D = null

# Persistente Daten zwischen Levels
var coins: int = 0
var current_health: int = 100
var max_health: int = 100
var attack_damage: int = 20

var finished_level:int = 1

var master_volume: float = 1.0
var music_volume: float = 0.75
var sfx_volume: float = 1.0
var fullscreen_enabled: bool = true


func _ready() -> void:
	load_settings()
	apply_display_settings()
	audio_settings_changed.emit()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_FILE)
	if err != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", master_volume)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
	fullscreen_enabled = bool(config.get_value("display", "fullscreen_enabled", fullscreen_enabled))


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	config.save(SETTINGS_FILE)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	save_settings()
	audio_settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	save_settings()
	audio_settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	save_settings()
	audio_settings_changed.emit()


func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	apply_display_settings()
	save_settings()
	display_settings_changed.emit()


func apply_display_settings() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)


func get_music_volume_db() -> float:
	return linear_to_db(max(master_volume * music_volume, 0.0001))


func get_sfx_volume_db() -> float:
	return linear_to_db(max(master_volume * sfx_volume, 0.0001))

extends Control

var game_paused : bool = false
const SETTINGS_ROOT := "MarginContainer/VBoxContainer"

@onready var main_panel: Panel = $Panel
@onready var controls_panel: Panel = $ControlsPanel
@onready var settings_panel: Panel = $SettingsPanel

func _ready() -> void:
	hide()
	if settings_panel:
		settings_panel.hide()
	_init_settings()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Wenn Settings offen sind → erst Settings schließen
		if visible and settings_panel and settings_panel.visible:
			_close_settings()
			get_viewport().set_input_as_handled()
			return
		game_paused = !game_paused
		_on_toggle_game_paused(game_paused)

func _on_toggle_game_paused(is_paused: bool) -> void:
	get_tree().paused = is_paused
	if is_paused:
		show()
	else:
		hide()
		if settings_panel:
			settings_panel.hide()

func _on_resume_pressed() -> void:
	game_paused = false
	_on_toggle_game_paused(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

# --- Settings ---
func _on_settings_pressed() -> void:
	if not settings_panel:
		return
	_init_settings()
	main_panel.hide()
	#if controls_panel:
		#controls_panel.hide()
	settings_panel.show()

func _close_settings() -> void:
	if not settings_panel:
		return
	settings_panel.hide()
	main_panel.show()
	if controls_panel:
		controls_panel.show()

func _on_back_pressed() -> void:
	_close_settings()

func _init_settings() -> void:
	if not settings_panel:
		return
	var master_slider := settings_panel.get_node_or_null("%s/MasterRow/MasterSlider" % SETTINGS_ROOT) as HSlider
	var music_slider := settings_panel.get_node_or_null("%s/MusicRow/MusicSlider" % SETTINGS_ROOT) as HSlider
	var sfx_slider := settings_panel.get_node_or_null("%s/SFXRow/SFXSlider" % SETTINGS_ROOT) as HSlider
	var fullscreen_check := settings_panel.get_node_or_null("%s/FullscreenCheck" % SETTINGS_ROOT) as Button

	if master_slider:
		master_slider.min_value = 0.0
		master_slider.max_value = 1.0
		master_slider.value = Global.master_volume
		if not master_slider.value_changed.is_connected(_on_master_changed):
			master_slider.value_changed.connect(_on_master_changed)
	if music_slider:
		music_slider.min_value = 0.0
		music_slider.max_value = 1.0
		music_slider.value = Global.music_volume
		if not music_slider.value_changed.is_connected(_on_music_changed):
			music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.min_value = 0.0
		sfx_slider.max_value = 1.0
		sfx_slider.value = Global.sfx_volume
		if not sfx_slider.value_changed.is_connected(_on_sfx_changed):
			sfx_slider.value_changed.connect(_on_sfx_changed)
	if fullscreen_check:
		fullscreen_check.button_pressed = Global.fullscreen_enabled
		if not fullscreen_check.toggled.is_connected(_on_fullscreen_toggled):
			fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func _on_master_changed(value: float) -> void:
	Global.set_master_volume(value)

func _on_music_changed(value: float) -> void:
	Global.set_music_volume(value)

func _on_sfx_changed(value: float) -> void:
	Global.set_sfx_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	Global.set_fullscreen_enabled(pressed)

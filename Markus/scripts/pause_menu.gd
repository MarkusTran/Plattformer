extends Control

var game_paused : bool = false

func _ready() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		game_paused = !game_paused
		_on_toggle_game_paused(game_paused)

func _on_toggle_game_paused(is_paused: bool) -> void:
	get_tree().paused = is_paused
	if is_paused:
		show()
	else:
		hide()

func _on_resume_pressed() -> void:
	game_paused = false
	_on_toggle_game_paused(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

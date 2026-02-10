extends Control

@export var game_manager : GameManager

var game_paused : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if (event.is_action_pressed("ui_cancel")):
		if (game_paused):
			game_paused = false
		else :
			game_paused = true
			
	_on_toggle_game_paused(game_paused)
		


func _on_toggle_game_paused(is_paused : bool):
	if(is_paused):
		get_tree().paused = true
		show()
	else:
		get_tree().paused = false
		hide()


func _on_resume_pressed() -> void:
	get_tree().paused = false


func _on_exit_pressed() -> void:
	get_tree().quit()

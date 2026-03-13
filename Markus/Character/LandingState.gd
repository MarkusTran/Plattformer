extends State
class_name LandingState

@export var ground_state: State

func on_enter() -> void:
	character.sprite2d.play("hitFist")
	# Warten bis Animation fertig → dann Ground
	character.sprite2d.animation_finished.connect(_on_landing_done, CONNECT_ONE_SHOT)

func _on_landing_done() -> void:
	next_state = ground_state

func on_exit() -> void:
	# Sicherheit: falls Signal noch hängt
	if character.sprite2d.animation_finished.is_connected(_on_landing_done):
		character.sprite2d.animation_finished.disconnect(_on_landing_done)

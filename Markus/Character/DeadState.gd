extends State
class_name DeadState

func on_enter() -> void:
	character.sprite2d.play("death")
	# Kein next_state — Dead ist final

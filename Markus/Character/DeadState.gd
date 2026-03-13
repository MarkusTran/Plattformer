extends State
class_name DeadState

func on_enter() -> void:
	character.sprite2d.play("dead")
	# Kein next_state — Dead ist final

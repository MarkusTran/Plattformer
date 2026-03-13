extends State
class_name HurtState

@export var ground_state: State

func on_enter() -> void:
	character.sprite2d.play("hitFist")
	character.sprite2d.animation_finished.connect(_on_hurt_done, CONNECT_ONE_SHOT)

func _on_hurt_done() -> void:
	next_state = ground_state

func on_exit() -> void:
	if character.sprite2d.animation_finished.is_connected(_on_hurt_done):
		character.sprite2d.animation_finished.disconnect(_on_hurt_done)

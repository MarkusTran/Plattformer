extends State
class_name AttackState

@export var ground_state: State

func on_enter() -> void:
	character.sprite2d.play("hitAxe")
	character.sprite2d.animation_finished.connect(_on_attack_done, CONNECT_ONE_SHOT)

func _on_attack_done() -> void:
	next_state = ground_state

func on_exit() -> void:
	if character.sprite2d.animation_finished.is_connected(_on_attack_done):
		character.sprite2d.animation_finished.disconnect(_on_attack_done)

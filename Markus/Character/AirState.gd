extends State
class_name AirState

@export var ground_state: State
@export var double_jump_velocity: float = -360.0

var has_double_jumped := false

func on_enter() -> void:
	character.sprite2d.play("hitAxe")

func state_process(delta: float) -> void:
	# Sprite wechseln je nach ob steigend oder fallend
	if character.velocity.y > 0:
		character.sprite2d.play("hitFist")

	if character.is_on_floor():
		next_state = ground_state
		has_double_jumped = false

func state_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and not has_double_jumped:
		character.velocity.y = double_jump_velocity
		has_double_jumped = true
		character.sprite2d.play("hitAxe")

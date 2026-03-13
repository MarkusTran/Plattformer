extends State
class_name GroundState

@export var jump_velocity: float = -420.0
@export var air_state: State
@export var attack_state: State
@export var hurt_state: State

func on_enter() -> void:
	character.sprite2d.play("idle")

func state_process(delta: float) -> void:
	if not character.is_on_floor():
		next_state = air_state
		return

	var dir = Input.get_axis("move_left", "move_right")
	if dir != 0:
		character.sprite2d.play("runAxe")
	else:
		character.sprite2d.play("idleAxe")

func state_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		character.velocity.y = jump_velocity
		next_state = air_state

	if event.is_action_pressed("attack"):
		next_state = attack_state

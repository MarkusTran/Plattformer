extends State
class_name AirState

@export var landing_state: State
@export var double_jump_velocity: float = -360.0
@export var attack_state: State  # ← Export hinzufügen

var has_double_jump := false
var _air_time := 0.0  # wie lange schon in der Luft

func on_enter() -> void:
	has_double_jump = false
	_air_time = 0.0
	character.sprite2d.play("jump")

func state_process(delta: float) -> void:
	_air_time += delta

	if character.velocity.y > 0:
		character.sprite2d.play("jumploop")

	# Erst nach 0.1s checken ob auf dem Boden — verhindert sofortigen Landing-Wechsel
	if _air_time > 0.1 and character.is_on_floor():
		next_state = landing_state

func state_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and not has_double_jump:
		character.velocity.y = double_jump_velocity
		has_double_jump = true
		character.sprite2d.play("double_jump")
		
	if event.is_action_pressed("attack"):
		next_state = attack_state

func on_exit() -> void:
	has_double_jump = false
	_air_time = 0.0

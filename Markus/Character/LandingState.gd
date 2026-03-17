extends State
class_name LandingState

@export var ground_state: State
@export var air_state: State
@export var jump_velocity: float = -420.0  # <- export damit du es im Editor anpassen kannst

var _landing_done := false

func on_enter() -> void:
	_landing_done = false
	character.sprite2d.play("landing")
	character.sprite2d.animation_finished.connect(_on_landing_done, CONNECT_ONE_SHOT)

func _on_landing_done() -> void:
	_landing_done = true

func state_process(delta: float) -> void:
	if _landing_done:
		next_state = ground_state
	if not character.sprite2d.is_playing():
		next_state = ground_state

func state_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		character.velocity.y = jump_velocity  # <- Velocity setzen!
		next_state = air_state

func on_exit() -> void:
	if character.sprite2d.animation_finished.is_connected(_on_landing_done):
		character.sprite2d.animation_finished.disconnect(_on_landing_done)
	_landing_done = false

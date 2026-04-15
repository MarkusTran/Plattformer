extends State
class_name AirState

@export var landing_state: State
@export var double_jump_velocity: float = -360.0
@export var attack_state: State  # ← Export hinzufügen

@onready var jump_sound: AudioStreamPlayer = get_node_or_null("../../Sounds/jump2")
@onready var airJump_Sound: AudioStreamPlayer = get_node_or_null("../../Sounds/airJump")

var has_double_jump := false
var _air_time := 0.0  # wie lange schon in der Luft

func on_enter() -> void:
	has_double_jump = false
	_air_time = 0.0
	character.sprite2d.play("jump")
	_play_sound(jump_sound)

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
		_play_sound(airJump_Sound)
		character.sprite2d.play("double_jump")
		
	if event.is_action_pressed("attack"):
		next_state = attack_state

func on_exit() -> void:
	has_double_jump = false
	_air_time = 0.0

func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()

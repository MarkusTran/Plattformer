extends State
class_name AttackState

@export var ground_state: State
@export var air_state: State

var _attack_done := false
var _combo_pressed := false
var _current_attack := 1

func on_enter() -> void:
	_attack_done = false
	_combo_pressed = false
	_current_attack = 1
	_play_attack(1)

func _play_attack(num: int) -> void:
	_current_attack = num
	_attack_done = false

	if character.sprite2d.animation_finished.is_connected(_on_attack_done):
		character.sprite2d.animation_finished.disconnect(_on_attack_done)

	# AnimatedSprite2D spielt die Animation
	character.sprite2d.play("attack" + str(num))
	character.sprite2d.animation_finished.connect(_on_attack_done, CONNECT_ONE_SHOT)

	# AnimationPlayer managed die Hitbox via Keyframes
	character.animation_player.play("attack" + str(num))

func _on_attack_done() -> void:
	_attack_done = true

func state_process(delta: float) -> void:
	if not _attack_done:
		return
	if _current_attack == 1 and _combo_pressed:
		_combo_pressed = false
		_play_attack(2)
		return
	if not character.is_on_floor():
		next_state = air_state
	else:
		next_state = ground_state

func state_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		if _current_attack == 1 and not _attack_done:
			_combo_pressed = true

func on_exit() -> void:
	if character.sprite2d.animation_finished.is_connected(_on_attack_done):
		character.sprite2d.animation_finished.disconnect(_on_attack_done)
	_attack_done = false
	_combo_pressed = false
	# Hitbox sicherheitshalber ausschalten
	character.end_attack()

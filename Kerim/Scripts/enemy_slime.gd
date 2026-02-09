extends CharacterBody2D

@export var player: CharacterBody2D
@export var player_group: String = "player"

@export var detection_range: float = 220.0

@export var jump_velocity: float = -300.0
@export var jump_cooldown: float = 0.9

@export var hop_speed: float = 140.0          # horizontale Hop-Geschwindigkeit
@export var stand_off: float = 26.0           # wie nah er "vor" dem Player landen will
@export var max_hop_speed: float = 160.0      # clamp, damit er nicht "schießt"

@export var max_health: int = 60

@onready var hitbox: Area2D = $Hitbox

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
var jump_timer := 0.0
var current_health := 0
var is_dead := false

func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")
	hitbox.add_to_group("enemy_hitbox")

	if not player:
		find_player()

func find_player() -> void:
	var players = get_tree().get_nodes_in_group(player_group)
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not player:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	jump_timer = max(0.0, jump_timer - delta)

	# Wenn Player zu weit weg: stehen bleiben
	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range:
		velocity.x = move_toward(velocity.x, 0, 600.0)
		move_and_slide()
		return

	# Nur springen, wenn am Boden & cooldown vorbei
	if is_on_floor() and jump_timer <= 0.0:
		do_hop_towards_player()
		jump_timer = jump_cooldown

	move_and_slide()

func do_hop_towards_player() -> void:
	var dx = player.global_position.x - global_position.x
	var dir_x = sign(dx)
	if dir_x == 0:
		dir_x = 1

	# Ziel: knapp vor dem Player landen
	var target_x = player.global_position.x - dir_x * stand_off

	# einfache Kontrolle: berechne benötigte vx über Flugzeit
	var t = (2.0 * abs(jump_velocity)) / gravity
	t = max(t, 0.18)

	var needed_vx = (target_x - global_position.x) / t
	needed_vx = clamp(needed_vx, -max_hop_speed, max_hop_speed)

	# wenn schon nahe genug, lieber "mini hop" (oder senkrecht)
	if abs(dx) < stand_off:
		needed_vx = 0.0

	velocity.y = jump_velocity
	velocity.x = needed_vx

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	queue_free()

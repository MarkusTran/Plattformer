extends CharacterBody2D

# Input actions
const MOVE_RIGHT_ACTION := "move_right"
const MOVE_LEFT_ACTION  := "move_left"
const JUMP_ACTION       := "ui_accept"
const SHOOT_ACTION      := "shoot"

@export var start_x: float = 482.0
@export var start_y: float = 531.0
@export var speed: float = 120.0
@export var jump_velocity: float = 350.0
@export var laser_prefab: PackedScene

var down_acceleration: float = 1.0

@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	position = Vector2(start_x, start_y)


func shoot() -> void:
	print("Pew Pew")

	if not Input.is_action_pressed(SHOOT_ACTION):
		return

	if laser_prefab == null:
		push_error("Laser Prefab is null")
		return

	var orb = laser_prefab.instantiate()
	orb.position = position + Vector2.RIGHT * 10.0
	get_parent().add_child(orb)


func _physics_process(delta: float) -> void:
	var v := velocity

	# Gravity
	if not is_on_floor():
		v += get_gravity() * delta * down_acceleration

	# Jump
	if Input.is_action_just_pressed(JUMP_ACTION) and is_on_floor():
		v.y -= jump_velocity

	# Move right
	if Input.is_action_pressed(MOVE_RIGHT_ACTION):
		animated_sprite.flip_h = false
		animated_sprite.play("run")
		v.x = speed

	# Move left
	if Input.is_action_pressed(MOVE_LEFT_ACTION):
		animated_sprite.flip_h = true
		animated_sprite.play("run")
		v.x = -speed

	# Shoot
	if Input.is_action_just_pressed(SHOOT_ACTION):
		if shoot_sound:
			shoot_sound.play()
		shoot()

	# Idle
	if not Input.is_action_pressed(MOVE_LEFT_ACTION) and not Input.is_action_pressed(MOVE_RIGHT_ACTION):
		animated_sprite.play("idle")
		v.x = move_toward(v.x, 0.0, speed)

	velocity = v
	move_and_slide()


func interaction() -> void:
	print("Interacting with object")


func damage_taken() -> void:
	print("Player took damage")

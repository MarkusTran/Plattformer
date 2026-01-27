extends CharacterBody2D

@export var player: CharacterBody2D
@export var WANDER_SPEED: int = 50
@export var CHASE_SPEED: int = 150
@export var JUMP_VELOCITY: int = -300
@export var JUMP_COOLDOWN: float = 1.0
@export var collision_offset: float = 0.0  # Passe dies im Inspector an!

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var chase_timer = $AnimatedSprite2D/Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2 = Vector2.ZERO
var right_bounds: Vector2
var left_bounds: Vector2
var jump_timer: float = 0.0

enum States {
	WANDER,
	CHASE
}

var current_state = States.WANDER

func _ready():
	left_bounds = self.position + Vector2(-125, 0)
	right_bounds = self.position + Vector2(125, 0)
	direction = Vector2(1, 0)
	sprite.play("default")

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	handle_jump(delta)
	look_for_player()
	update_sprite_direction()
	update_animation()
	move_and_slide()

func look_for_player() -> void:
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		if collider == player:
			chase_player()
		elif current_state == States.CHASE:
			stop_chase()

func chase_player() -> void:
	chase_timer.stop()
	current_state = States.CHASE

func stop_chase() -> void:
	if chase_timer.time_left <= 0:
		chase_timer.start()

func handle_jump(delta: float) -> void:
	jump_timer -= delta
	
	if not is_on_floor():
		return
	
	if jump_timer > 0:
		return
	
	if current_state == States.WANDER:
		handle_wander_jump()
	else:
		handle_chase_jump()

func handle_wander_jump() -> void:
	if direction.x > 0 and self.position.x >= right_bounds.x:
		direction.x = -1
	elif direction.x < 0 and self.position.x <= left_bounds.x:
		direction.x = 1
	
	velocity.y = JUMP_VELOCITY
	velocity.x = direction.x * WANDER_SPEED
	jump_timer = JUMP_COOLDOWN

func handle_chase_jump() -> void:
	var direction_to_player = (player.position - self.position).normalized()
	direction.x = sign(direction_to_player.x)
	
	velocity.y = JUMP_VELOCITY
	velocity.x = direction.x * CHASE_SPEED
	jump_timer = JUMP_COOLDOWN * 0.5

func update_sprite_direction() -> void:
	if direction.x > 0:
		sprite.flip_h = false
		ray_cast.target_position = Vector2(125, 0)
		# Collision nach rechts verschieben
		collision_shape.position.x = collision_offset
	elif direction.x < 0:
		sprite.flip_h = true
		ray_cast.target_position = Vector2(-125, 0)
		# Collision nach links verschieben
		collision_shape.position.x = -collision_offset

func update_animation() -> void:
	if sprite.sprite_frames != null:
		sprite.play("default")

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _on_timer_timeout():
	current_state = States.WANDER

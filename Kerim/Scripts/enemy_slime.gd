extends CharacterBody2D

@export var player: CharacterBody2D
@export var player_group: String = "player"
@export var WANDER_SPEED: int = 50
@export var CHASE_SPEED: int = 150
@export var JUMP_VELOCITY: int = -300
@export var JUMP_COOLDOWN: float = 1.0
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_cooldown: float = 1.5
@export var attack_range: float = 40.0
@export var detection_range: float = 200.0
@export var sprite_collision_offset: float = -12.15

@onready var flip_root: Node2D = $FlipRoot # Falls du es so genannt hast
@onready var sprite: AnimatedSprite2D = $FlipRoot/AnimatedSprite2D
@onready var ray_cast: RayCast2D = $FlipRoot/AnimatedSprite2D/RayCast2D
@onready var chase_timer: Timer = $FlipRoot/AnimatedSprite2D/Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $CanvasLayer/ProgressBar

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2 = Vector2.ZERO
var right_bounds: Vector2
var left_bounds: Vector2
var jump_timer: float = 0.0
var current_health: int
var attack_timer: float = 0.0
var is_dead: bool = false

var collision_original_pos: Vector2
var last_direction: float = 1.0  # DEBUG

enum States {
	WANDER,
	CHASE,
	ATTACK
}

var current_state = States.WANDER

func _ready():
	left_bounds = self.position + Vector2(-125, 0)
	right_bounds = self.position + Vector2(125, 0)
	direction = Vector2(1, 0)
	
	collision_original_pos = collision_shape.position
	current_health = max_health
	sprite.play("default")

	if not player:
		find_player()
		
	if not player:
		push_warning("Slime: Kein Player gefunden!")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		health_bar.position = Vector2(-20, -40)
		health_bar.size = Vector2(40, 5)
	
	print("=== DEBUG START ===")
	print("Collision Shape gefunden: ", collision_shape != null)
	print("Collision Original Position: ", collision_original_pos)
	print("Sprite Collision Offset: ", sprite_collision_offset)
	print("===================")

func find_player() -> void:
	var players = get_tree().get_nodes_in_group(player_group)
	if players.size() > 0:
		player = players[0]
		return
	
	var root = get_tree().current_scene
	player = root.find_child("Player*", true, false)
	if player:
		return

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not player:
		return
	
	handle_gravity(delta)
	check_player_distance()
	handle_attack(delta)
	handle_jump(delta)
	update_sprite_and_collision_direction()
	update_animation()
	update_healthbar()
	move_and_slide()

func check_player_distance() -> void:
	if not player:
		return
	
	var distance = self.position.distance_to(player.position)
	
	if distance <= attack_range and is_on_floor():
		current_state = States.ATTACK
		velocity.x = 0
		return
	
	if distance <= detection_range:
		if can_see_player():
			if current_state == States.WANDER:
				chase_player()
		elif current_state == States.CHASE or current_state == States.ATTACK:
			stop_chase()
	else:
		if current_state == States.CHASE or current_state == States.ATTACK:
			stop_chase()

func can_see_player() -> bool:
	if not player:
		return false
	
	ray_cast.target_position = ray_cast.to_local(player.global_position)
	ray_cast.force_raycast_update()
	
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		return collider == player
	
	return false
	
func update_healthbar() -> void:
	if health_bar:
		health_bar.value = current_health

func chase_player() -> void:
	chase_timer.stop()
	if current_state != States.ATTACK:
		current_state = States.CHASE

func stop_chase() -> void:
	if chase_timer.time_left <= 0:
		chase_timer.start()

func handle_attack(delta: float) -> void:
	if not player:
		return
		
	attack_timer -= delta
	
	if current_state == States.ATTACK:
		velocity.x = 0
		
		if attack_timer <= 0:
			var distance = self.position.distance_to(player.position)
			
			if distance <= attack_range:
				if player.has_method("take_damage"):
					player.take_damage(attack_damage)
				attack_timer = attack_cooldown
			else:
				current_state = States.CHASE
				attack_timer = 0

func handle_jump(delta: float) -> void:
	if current_state == States.ATTACK:
		velocity.x = 0
		return
	
	jump_timer -= delta
	
	if not is_on_floor():
		return
	
	if jump_timer > 0:
		return
	
	if current_state == States.WANDER:
		handle_wander_jump()
	elif current_state == States.CHASE:
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
	if not player:
		return
	
	var direction_to_player = (player.position - self.position).normalized()
	direction.x = sign(direction_to_player.x)
	
	velocity.y = JUMP_VELOCITY
	velocity.x = direction.x * CHASE_SPEED
	jump_timer = JUMP_COOLDOWN * 0.5

func update_sprite_and_collision_direction() -> void:
	if (current_state == States.CHASE or current_state == States.ATTACK) and player:
		direction.x = sign(player.position.x - self.position.x)
	
	if direction.x == 0:
		direction.x = 1
		
	# Anstatt flip_h und Collision-Offset:
	if direction.x > 0:
		flip_root.scale.x = 1  # Schaut nach rechts
	elif direction.x < 0:
		flip_root.scale.x = -1 # Schaut nach links (alles darin wird gespiegelt)
		
func update_animation() -> void:
	if sprite.sprite_frames != null:
		sprite.play("default")

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	current_health -= amount
	
	if health_bar:
		health_bar.value = current_health
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	
	if health_bar:
		health_bar.hide()
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	
	queue_free()

func _on_timer_timeout():
	if current_state != States.ATTACK:
		current_state = States.WANDER

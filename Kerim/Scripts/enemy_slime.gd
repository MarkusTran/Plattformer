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
@export var attack_range: float = 40.0  # Etwas größer machen
@export var detection_range: float = 200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var chase_timer = $AnimatedSprite2D/Timer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: ProgressBar = $CanvasLayer/ProgressBar

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: Vector2 = Vector2.ZERO
var right_bounds: Vector2
var left_bounds: Vector2
var jump_timer: float = 0.0
var collision_original_x: float
var current_health: int
var attack_timer: float = 0.0
var is_dead: bool = false

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
	collision_original_x = collision_shape.position.x
	current_health = max_health
	sprite.play("default")

	if not player:
		find_player()
		
	if not player:
		push_warning("Slime: Kein Player gefunden! Bitte Player-Referenz setzen oder Player zur Gruppe 'player' hinzufügen.")
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		health_bar.position = Vector2(-20, -40)
		health_bar.size = Vector2(40, 5)

func find_player() -> void:
	var players = get_tree().get_nodes_in_group(player_group)
	if players.size() > 0:
		player = players[0]
		print("Slime: Player über Gruppe gefunden!")
		return
	
	var root = get_tree().current_scene
	player = root.find_child("Player*", true, false)
	if player:
		print("Slime: Player über Node-Namen gefunden!")
		return
	
	for node in get_tree().get_nodes_in_group(""):
		if node is CharacterBody2D and node != self:
			if node.has_method("take_damage") and node.has_method("die"):
				player = node
				print("Slime: Player über Script-Methoden gefunden!")
				return

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if not player:
		return
	
	handle_gravity(delta)
	check_player_distance()  # Zuerst Zustand bestimmen
	handle_attack(delta)     # Dann angreifen (wenn im ATTACK Zustand)
	handle_jump(delta)       # Dann erst springen (wird im ATTACK blockiert)
	update_sprite_direction()
	update_animation()
	update_healthbar()
	move_and_slide()

func check_player_distance() -> void:
	if not player:
		return
	
	var distance = self.position.distance_to(player.position)
	
	# Wenn Player sehr nah ist UND auf dem Boden -> ATTACK
	if distance <= attack_range and is_on_floor():
		if current_state != States.ATTACK:
			print("Wechsel zu ATTACK! Distanz: ", distance)
		current_state = States.ATTACK
		velocity.x = 0  # WICHTIG: Sofort stoppen!
		return
	
	# Wenn Player in Detection Range und sichtbar -> CHASE
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
	
	var direction_to_player = player.global_position - ray_cast.global_position
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
		print("Wechsel zu CHASE!")

func stop_chase() -> void:
	if chase_timer.time_left <= 0:
		chase_timer.start()

func handle_attack(delta: float) -> void:
	if not player:
		return
		
	attack_timer -= delta
	
	if current_state == States.ATTACK:
		# Stelle sicher dass der Slime steht
		velocity.x = 0
		
		# Nur angreifen wenn Cooldown abgelaufen
		if attack_timer <= 0:
			var distance = self.position.distance_to(player.position)
			
			# Prüfe ob Player noch in Range ist
			if distance <= attack_range:
				if player.has_method("take_damage"):
					player.take_damage(attack_damage)
					print("SLIME GREIFT AN! Damage: ", attack_damage, " | Distanz: ", distance)
				attack_timer = attack_cooldown
			else:
				# Player ist weggelaufen
				print("Player zu weit weg, wechsel zu CHASE")
				current_state = States.CHASE
				attack_timer = 0  # Reset timer

func handle_jump(delta: float) -> void:
	# WICHTIG: Im ATTACK-Modus NIE springen!
	if current_state == States.ATTACK:
		velocity.x = 0  # Sicherstellen dass keine horizontale Bewegung
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

func update_sprite_direction() -> void:
	# Bestimme Richtung basierend auf Player-Position im Chase/Attack
	if (current_state == States.CHASE or current_state == States.ATTACK) and player:
		direction.x = sign(player.position.x - self.position.x)
	
	# KORRIGIERT: Wenn Sprite nach rechts schaut (flip_h = false), ist die Collision richtig
	# Also: flip_h = false (nach rechts) → Original Position
	#       flip_h = true (nach links) → Gespiegelte Position
	if direction.x > 0:
		# Nach rechts schauen
		sprite.flip_h = false
		collision_shape.position.x = collision_original_x  # Original Position (richtig)
	elif direction.x < 0:
		# Nach links schauen
		sprite.flip_h = true
		collision_shape.position.x = -collision_original_x  # Gespiegelte Position

func update_animation() -> void:
	if sprite.sprite_frames != null:
		if current_state == States.ATTACK:
			sprite.play("default")  # TODO: Attack animation
		else:
			sprite.play("default")

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func take_damage(amount: int) -> void:
	if is_dead:
		return
	
	current_health -= amount
	print("Slime nimmt ", amount, " Schaden! Health: ", current_health)
	
	if health_bar:
		health_bar.value = current_health
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die() -> void:
	is_dead = true
	print("Slime ist gestorben!")
	
	if health_bar:
		health_bar.hide()
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	
	queue_free()

func _on_timer_timeout():
	if current_state != States.ATTACK:
		current_state = States.WANDER
		print("Timer abgelaufen, zurück zu WANDER")

extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -500.0

@export var max_health: int = 100
@export var attack_damage: int = 30
@export var attack_range: float = 40.0

var current_health: int
var is_attacking: bool = false

func _ready():
	current_health = max_health

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# Angriff mit Taste (z.B. Space oder Mausklick)
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

	move_and_slide()
	
func attack() -> void:
		is_attacking = true
		# Spiele Attack-Animation
		# $AnimatedSprite2D.play("attack")
		
		# Finde alle Gegner in Reichweite
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		
		# Erstelle einen Kreis für die Angriffs-Range
		var shape = CircleShape2D.new()
		shape.radius = attack_range
		query.shape = shape
		query.transform = global_transform
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var results = space_state.intersect_shape(query)
		
		for result in results:
			var body = result.collider
			if body.has_method("take_damage") and body != self:
				body.take_damage(attack_damage)
		
		# Warte kurz bevor nächster Angriff möglich ist
		await get_tree().create_timer(0.5).timeout
		is_attacking = false

func take_damage(amount: int) -> void:
	current_health -= amount
	print("Player nimmt ", amount, " Schaden! Health: ", current_health)
	
	# Flash-Effekt
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Player ist gestorben!")
	# Game Over Logik hier
	get_tree().reload_current_scene()

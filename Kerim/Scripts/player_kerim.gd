extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -500.0

@export var max_health: int = 100
@export var invincible_time: float = 0.4

@export var touch_damage: int = 10
@export var knockback_x: float = 260.0
@export var knockback_y: float = 180.0
@export var knockback_lock: float = 0.18

@export var attack_damage: int = 30
@export var attack_range: float = 40.0

var current_health: int
var invincible := false
var is_attacking := false
var already_hit := {}  # instance_id -> true
var is_dead := false

var kb_time := 0.0

@onready var hurtbox: Area2D = $Hurtbox

var last_hit_time_by_enemy := {}  # Dictionary
@export var enemy_hit_cooldown := 0.35

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

func _ready() -> void:
	Global.playerBody = self
	current_health = max_health

	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.disabled = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Knockback lock: kurz keine Inputs
	if kb_time > 0.0:
		kb_time -= delta
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var dir := Input.get_axis("move_left", "move_right")
	if dir:
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	move_and_slide()

func start_attack() -> void:
	if is_attacking or is_dead:
		return

	is_attacking = true
	already_hit.clear()

	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	attack_shape.disabled = false

	await get_tree().create_timer(0.15).timeout

	if is_inside_tree():
		end_attack()

func end_attack() -> void:
	is_attacking = false
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.disabled = true

func _on_attack_hitbox_body_entered(body: Node) -> void:
	if not is_attacking:
		return

	if body == self:
		return

	if not body.has_method("take_damage"):
		return

	var id := body.get_instance_id()
	if already_hit.has(id):
		return

	already_hit[id] = true
	body.take_damage(attack_damage)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("Etwas hat die Hurtbox berührt: ", area.name)

	if is_dead:
		return

	if not area.is_in_group("enemy_hitbox"):
		return

	var enemy := area.get_parent() as CharacterBody2D
	if enemy == null:
		return

	var dangerous: bool = (
		not enemy.is_on_floor()
		or abs(enemy.velocity.x) >= 30
		or enemy.velocity.y > 40
	)

	if not dangerous:
		return

	take_damage(touch_damage, _get_knockback_dir_from_position(area.global_position))

func _get_knockback_dir_from_position(from_pos: Vector2) -> Vector2:
	var dir_x: float = sign(global_position.x - from_pos.x)
	if dir_x == 0:
		dir_x = 1
	return Vector2(dir_x, -0.7).normalized()

func apply_knockback(from_pos: Vector2) -> void:
	kb_time = knockback_lock
	var dir: float = sign(global_position.x - from_pos.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * knockback_x
	velocity.y = -abs(knockback_y)

func apply_knockback_dir(dir: Vector2) -> void:
	kb_time = knockback_lock

	var final_dir := dir
	if final_dir == Vector2.ZERO:
		final_dir = Vector2(1, -0.7)

	final_dir = final_dir.normalized()

	velocity.x = final_dir.x * knockback_x
	velocity.y = final_dir.y * knockback_y

	if velocity.y > 0:
		velocity.y = -abs(knockback_y)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if invincible:
		return
	if is_dead:
		return

	invincible = true
	current_health -= amount
	print("Player nimmt ", amount, " Schaden! Health: ", current_health)

	if knockback_dir != Vector2.ZERO:
		apply_knockback_dir(knockback_dir)

	if current_health <= 0:
		die()
		return

	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout

	if not is_inside_tree() or is_dead:
		return

	modulate = Color.WHITE

	await get_tree().create_timer(invincible_time).timeout

	if not is_inside_tree() or is_dead:
		return

	invincible = false

func die() -> void:
	if is_dead:
		return

	is_dead = true
	print("Player ist gestorben!")
	get_tree().reload_current_scene()

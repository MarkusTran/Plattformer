extends CharacterBody2D
class_name GoblinEnemy

const SPEED := 30.0
const GRAVITY := 900.0

@export var damage_to_deal: int = 20
@export var attack_cooldown: float = 1.0
@export var attack_distance: float = 45.0

var health := 80
var dead := false
var taking_damage := false

var dir: Vector2 = Vector2.LEFT
var player_in_range := false
var is_attacking := false
var can_attack := true

@export var player: CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var hit_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var attack_range: Area2D = $AttackRange

var already_hit := {}

func _ready() -> void:
	player = Global.playerBody

	# Hitbox standardmäßig AUS (sicher: monitoring + shape)
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	hit_shape.disabled = true

	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)

	anim_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = 0
		apply_gravity(delta)
		move_and_slide()
		return

	apply_gravity(delta)

	if player == null:
		move_and_slide()
		return

	# Wenn wir gerade angreifen oder Schaden nehmen: nicht laufen/chasen
	if taking_damage or is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	# Basic Chase
	var dx := player.global_position.x - global_position.x
	dir.x = signf(dx) if dx != 0 else dir.x

	update_facing()

	if player_in_range and can_attack:
		start_attack()
	else:
		velocity.x = dir.x * SPEED
		anim_sprite.play("walk")

	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func update_facing() -> void:
	if dir.x < 0:
		anim_sprite.flip_h = true
		attack_hitbox.scale.x = -abs(attack_hitbox.scale.x)
	elif dir.x > 0:
		anim_sprite.flip_h = false
		attack_hitbox.scale.x = abs(attack_hitbox.scale.x)

func start_attack() -> void:
	if attack_distance > 0.0 and player != null:
		if global_position.distance_to(player.global_position) > attack_distance:
			return

	is_attacking = true
	can_attack = false
	already_hit.clear()

	velocity.x = 0

	# Deine Sprite-Attack-Animation heißt "attack"
	anim_sprite.play("attack")

	# AnimationPlayer läuft parallel nur fürs Hitbox-Timing
	anim_player.play("attack")

	get_tree().create_timer(attack_cooldown).timeout.connect(func():
		can_attack = true
	)

# Wird vom AnimationPlayer per Call-Method-Keyframe aufgerufen
func enable_attack_hitbox() -> void:
	attack_hitbox.monitorable = true
	attack_hitbox.monitoring = true
	hit_shape.disabled = false

# Wird vom AnimationPlayer per Call-Method-Keyframe aufgerufen
func disable_attack_hitbox() -> void:
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	hit_shape.disabled = true

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if dead or not is_attacking:
		return
	if player == null:
		return
	if area != player.hurtbox:
		return

	if already_hit.has(player.get_instance_id()):
		return

	already_hit[player.get_instance_id()] = true
	player.take_damage(damage_to_deal)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"attack":
		disable_attack_hitbox()
		is_attacking = false

func _on_attack_range_body_entered(body: Node) -> void:
	if body == player:
		player_in_range = true

func _on_attack_range_body_exited(body: Node) -> void:
	if body == player:
		player_in_range = false

func take_damage(dmg: int) -> void:
	if dead:
		return

	health -= dmg
	taking_damage = true
	anim_sprite.play("hurt")

	if health <= 0:
		health = 0
		dead = true
		anim_sprite.play("death")
		await get_tree().create_timer(1.0).timeout
		queue_free()
		return

	await get_tree().create_timer(0.4).timeout
	taking_damage = false

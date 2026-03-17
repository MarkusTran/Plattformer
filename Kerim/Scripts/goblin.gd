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

var hit_lock := false

@export var player: CharacterBody2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var hit_shape1: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var hit_shape2: CollisionShape2D = $AttackHitbox/CollisionShape2D2
@onready var attack_range: Area2D = $AttackRange

@export var hurt_invuln_time: float = 0.35
var invulnerable := false

var already_hit := {}

func _ready() -> void:
	# Hitbox standardmäßig AUS
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	hit_shape1.disabled = true
	hit_shape2.disabled = true



func _physics_process(delta: float) -> void:
	
	if player == null:
		var players = get_tree().get_nodes_in_group("player")
		if player.size()>0:
			player = players[0] as CharacterBody2D
		move_and_slide()
		return
	
	if dead:
		velocity.x = 0
		apply_gravity(delta)
		move_and_slide()
		return

	apply_gravity(delta)

	if player == null:
		move_and_slide()
		return

	# Hurt hat Priorität (Animation darf nicht überschrieben werden)
	if taking_damage:
		velocity.x = 0
		move_and_slide()
		return

	# Attack läuft gerade
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	# Chase Richtung
	var dx := player.global_position.x - global_position.x
	dir.x = signf(dx) if dx != 0 else dir.x
	update_facing()

	#print("STATE:",
		#" in_range=", player_in_range,
		#" can_attack=", can_attack,
		#" taking=", taking_damage,
		#" attacking=", is_attacking
	#)

	# Attack starten
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
	if dead or taking_damage or is_attacking:
		return

	#print("START_ATTACK CALLED")

	if player == null:
		return

	var dist := global_position.distance_to(player.global_position)
	#print("DIST=", dist, " attack_distance=", attack_distance)

	if dist > attack_distance:
		#print("TOO FAR -> RETURN")
		return

	is_attacking = true
	can_attack = false
	already_hit.clear()

	velocity.x = 0

	# Sprite-Attack Animation
	anim_sprite.play("attack")

	# AnimationPlayer nur fürs Hitbox-Timing
	anim_player.play("attack")

	get_tree().create_timer(attack_cooldown).timeout.connect(func():
		can_attack = true
	)

func enable_attack_hitbox() -> void:
	if dead or taking_damage or not is_attacking:
		return
	call_deferred("_set_attack_hitbox_enabled", true)

func disable_attack_hitbox() -> void:
	call_deferred("_set_attack_hitbox_enabled", false)

func _set_attack_hitbox_enabled(enabled: bool) -> void:
	attack_hitbox.set_deferred("monitoring", enabled)
	attack_hitbox.set_deferred("monitorable", enabled)
	hit_shape1.set_deferred("disabled", not enabled)
	hit_shape2.set_deferred("disabled", not enabled)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	print("HITBOX ENTER:", area.name)
	if dead or not is_attacking:
		return
	if player == null:
		return
	if area != player.hurtbox:
		return

	# nur 1x pro Swing
	var pid := player.get_instance_id()
	if already_hit.has(pid):
		return

	already_hit[pid] = true
	player.take_damage(damage_to_deal)

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"attack":
		disable_attack_hitbox()
		is_attacking = false

func _on_attack_range_body_entered(body: Node) -> void:
	#print("RANGE ENTER:", body.name)
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		player_in_range = true
		#print("PLAYER IN RANGE TRUE")

func _on_attack_range_body_exited(body: Node) -> void:
	#print("RANGE EXIT:", body.name)
	if body == player:
		player_in_range = false

func take_damage(dmg: int) -> void:
	if dead or hit_lock:
		return

	hit_lock = true
	health -= dmg

	# Attack sofort komplett abbrechen
	is_attacking = false
	can_attack = false
	player_in_range = false
	anim_player.stop()
	disable_attack_hitbox()

	if health <= 0:
		dead = true
		taking_damage = true

		anim_sprite.play("death")
		await anim_sprite.animation_finished
		queue_free()
		return

	taking_damage = true
	anim_sprite.play("hurt")
	await anim_sprite.animation_finished
	taking_damage = false

	await get_tree().create_timer(hurt_invuln_time).timeout
	hit_lock = false
	can_attack = true

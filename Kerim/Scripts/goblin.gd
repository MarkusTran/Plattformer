extends BaseEnemy
class_name GoblinEnemy

const GRAVITY := 900.0

@export var walk_speed: float = 38.0
@export var chase_speed: float = 62.0
@export var aggro_range: float = 360.0
@export var give_up_range: float = 460.0
@export var leash_distance: float = 420.0
@export var return_tolerance: float = 6.0
@export var facing_deadzone: float = 18.0
@export var turn_cooldown: float = 0.2
@export var aggro_vertical_range: float = 170.0
@export var give_up_vertical_range: float = 230.0
@export var vertical_tolerance: float = 42.0
@export var damage_to_deal: int = 20
@export var attack_cooldown: float = 1.0
@export var attack_distance: float = 45.0
@export var hold_distance: float = 28.0
@export var jump_velocity: float = -410.0
@export var jump_forward_speed: float = 72.0
@export var jump_trigger_height: float = 36.0
@export var jump_horizontal_window: float = 120.0
@export var jump_cooldown: float = 0.9
@export var knockback_force: float = 200.0
@export var hurt_invuln_time: float = 0.35

var taking_damage := false
var dir: Vector2 = Vector2.LEFT
var player_in_range := false
var is_attacking := false
var can_attack := true
var hit_lock := false
var has_aggro := false
var spawn_position := Vector2.ZERO
var jump_cooldown_left := 0.0
var facing_dir := -1
var turn_cooldown_left := 0.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var hit_shape1: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var hit_shape2: CollisionShape2D = $AttackHitbox/CollisionShape2D2
@onready var attack_range: Area2D = $AttackRange

@onready var slash_sound: AudioStreamPlayer = get_node_or_null("Sound/slash")
@onready var step_sound: AudioStreamPlayer = get_node_or_null("Sound/step")

var invulnerable := false
var already_hit := {}

func _ready() -> void:
	super._ready()
	spawn_position = global_position
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	hit_shape1.disabled = true
	hit_shape2.disabled = true
	anim_sprite.play("idle")

func on_hit() -> void:
	anim_sprite.play("hurt")

func on_death() -> void:
	taking_damage = true
	is_attacking = false
	has_aggro = false
	anim_player.stop()
	disable_attack_hitbox()
	anim_sprite.play("death")
	await anim_sprite.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_find_player()

	jump_cooldown_left = maxf(0.0, jump_cooldown_left - delta)
	turn_cooldown_left = maxf(0.0, turn_cooldown_left - delta)

	if is_dead:
		velocity.x = 0.0
		apply_gravity(delta)
		move_and_slide()
		return

	apply_gravity(delta)

	
	if taking_damage:
		velocity.x = 0.0
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	_update_aggro()

	if _can_start_attack():
		start_attack()
	elif has_aggro:
		_chase_player()
	else:
		_return_to_spawn()

	move_and_slide()
	_update_animation()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func update_facing() -> void:
	if facing_dir < 0:
		anim_sprite.flip_h = true
		attack_hitbox.scale.x = -abs(attack_hitbox.scale.x)
	elif facing_dir > 0:
		anim_sprite.flip_h = false
		attack_hitbox.scale.x = abs(attack_hitbox.scale.x)

func start_attack() -> void:
	if is_dead or taking_damage or is_attacking or not _can_start_attack():
		return

	is_attacking = true
	can_attack = false
	already_hit.clear()
	velocity.x = 0.0
	_play_sound(slash_sound)
	anim_sprite.play("attack")
	anim_player.play("attack")

	get_tree().create_timer(attack_cooldown).timeout.connect(func():
		if is_inside_tree() and not is_dead:
			can_attack = true
	)

func enable_attack_hitbox() -> void:
	if is_dead or taking_damage or not is_attacking:
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
	if is_dead or not is_attacking:
		return
	if player == null or not is_instance_valid(player):
		return
	if area != player.hurtbox:
		return

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
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		player_in_range = true

func _on_attack_range_body_exited(body: Node) -> void:
	if body == player:
		player_in_range = false

func _on_direction_timer_timeout() -> void:
	pass

func take_damage(dmg: int) -> void:
	if is_dead or hit_lock:
		return

	hit_lock = true
	current_health -= dmg
	has_aggro = true

	is_attacking = false
	can_attack = false
	player_in_range = false
	anim_player.stop()
	disable_attack_hitbox()

	if current_health <= 0:
		super.die()
		return

	if player != null and is_instance_valid(player):
		var knockback_dir: float = signf(global_position.x - player.global_position.x)
		if knockback_dir == 0:
			knockback_dir = 1
		velocity.x = knockback_dir * knockback_force
		velocity.y = -80.0

	taking_damage = true
	modulate = Color(1.0, 0.3, 0.3)
	anim_sprite.play("hurt")
	await anim_sprite.animation_finished
	if not is_inside_tree() or is_dead:
		return
	modulate = Color.WHITE
	taking_damage = false

	await get_tree().create_timer(hurt_invuln_time).timeout
	if not is_inside_tree() or is_dead:
		return
	hit_lock = false
	can_attack = true

func _update_aggro() -> void:
	if player == null or not is_instance_valid(player):
		has_aggro = false
		player_in_range = false
		return

	var player_offset := player.global_position - global_position
	var horizontal_distance := absf(player_offset.x)
	var vertical_distance := absf(player_offset.y)
	var distance_to_spawn := absf(global_position.x - spawn_position.x)

	if has_aggro:
		if horizontal_distance > give_up_range:
			has_aggro = false
		elif vertical_distance > give_up_vertical_range:
			has_aggro = false
		elif distance_to_spawn > leash_distance:
			has_aggro = false
	elif horizontal_distance <= aggro_range and vertical_distance <= aggro_vertical_range:
		has_aggro = true

func _can_start_attack() -> bool:
	if not has_aggro or not player_in_range or not can_attack:
		return false
	if player == null or not is_instance_valid(player):
		return false
	if absf(player.global_position.y - global_position.y) > vertical_tolerance:
		return false
	return global_position.distance_to(player.global_position) <= attack_distance

func _chase_player() -> void:
	if player == null or not is_instance_valid(player):
		_return_to_spawn()
		return

	var dx := player.global_position.x - global_position.x
	var dy := player.global_position.y - global_position.y

	if _should_jump_towards_player(dx, dy):
		_do_jump_towards_player(dx)
		return

	if dy < -jump_trigger_height:
		_align_for_jump(dx)
		return

	if absf(dx) <= hold_distance:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		return

	var move_dir := _get_stable_horizontal_direction(dx)
	dir.x = move_dir
	update_facing()
	velocity.x = dir.x * chase_speed

func _should_jump_towards_player(dx: float, dy: float) -> bool:
	if not is_on_floor():
		return false
	if jump_cooldown_left > 0.0:
		return false
	if dy > -jump_trigger_height:
		return false
	if absf(dx) > jump_horizontal_window:
		return false
	return true

func _do_jump_towards_player(dx: float) -> void:
	var jump_dir := _get_stable_horizontal_direction(dx)
	if jump_dir == 0.0:
		jump_dir = facing_dir if facing_dir != 0 else 1.0
	dir.x = jump_dir
	update_facing()
	velocity.y = jump_velocity
	velocity.x = jump_dir * jump_forward_speed
	jump_cooldown_left = jump_cooldown

func _align_for_jump(dx: float) -> void:
	if absf(dx) <= facing_deadzone:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		return

	var move_dir := _get_stable_horizontal_direction(dx)
	dir.x = move_dir
	update_facing()
	velocity.x = dir.x * chase_speed * 0.75

func _return_to_spawn() -> void:
	var dx := spawn_position.x - global_position.x
	if absf(dx) <= return_tolerance:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		return

	dir.x = _get_stable_horizontal_direction(dx)
	update_facing()
	velocity.x = dir.x * walk_speed

func _get_stable_horizontal_direction(dx: float) -> float:
	if absf(dx) <= facing_deadzone:
		return facing_dir

	var desired_dir := -1 if dx < 0.0 else 1
	if desired_dir != facing_dir and turn_cooldown_left > 0.0:
		return facing_dir
	if desired_dir != facing_dir and not is_on_floor():
		return facing_dir

	if desired_dir != facing_dir:
		facing_dir = desired_dir
		turn_cooldown_left = turn_cooldown

	return facing_dir

func _update_animation() -> void:
	if is_dead or taking_damage or is_attacking:
		return
	if absf(velocity.x) > 3.0:
		if anim_sprite.animation != "walk":
			_play_sound(step_sound)
			anim_sprite.play("walk")
	else:
		if anim_sprite.animation != "idle":
			anim_sprite.play("idle")
			
func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()

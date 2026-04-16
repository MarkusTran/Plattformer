extends CharacterBody2D
class_name MinotaurBoss

@export var move_speed: float = 55.0
@export var phase_two_move_speed: float = 82.0
@export var phase_three_move_speed: float = 105.0
@export var aggro_range: float = 260.0
@export var attack_distance: float = 62.0
@export var attack_damage: int = 22
@export var touch_damage: int = 10
@export var touch_damage_cooldown: float = 0.7
@export var attack_cooldown: float = 1.4
@export var phase_two_attack_cooldown: float = 0.9
@export var phase_three_attack_cooldown: float = 0.6
@export var max_health: int = 220
@export var hurt_invuln_time: float = 0.3
@export var hurt_cooldown: float = 0.8
@export var super_armor_during_attack: bool = true
@export var death_linger_time: float = 1.2
@export var phase_shift_pause: float = 0.35
@export_range(0.05, 0.3, 0.01) var phase_three_health_threshold: float = 0.15
@export var hit_active_from_frame: int = 3
@export var hit_active_to_frame: int = 4
@export var attack_hitbox_offset_x: float = 34.0
@export var player_group: String = "player"
@export var fall_respawn_distance: float = 900.0

@onready var sprite: AnimatedSprite2D = $FlipRoot/AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var attack_range_shape: CollisionShape2D = $AttackRange/CollisionShape2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var touch_damage_area: Area2D = $TouchDamageArea
@onready var boss_health_bar: ProgressBar = $CanvasLayer/BossHealthUI/ProgressBar
@onready var phase_label: Label = $CanvasLayer/PhaseLabel
@onready var hp_label: Label = $CanvasLayer/BossHealthUI/HPLabel

@onready var slash_sound: AudioStreamPlayer = get_node_or_null("Sound/slash")
@onready var step_sound: AudioStreamPlayer = get_node_or_null("Sound/step")

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
var current_health := 0
var player: CharacterBody2D
var facing_dir := -1
var is_dead := false
var is_attacking := false
var is_hurt := false
var can_attack := true
var hitbox_active := false
var hit_targets := {}
var can_be_hurt := true
var is_phase_two := false
var is_phase_three := false
var touch_targets := {}
var is_phase_shifting := false
var boss_music_playing := false
var spawn_position := Vector2.ZERO

func _ready() -> void:
	current_health = max_health
	spawn_position = global_position
	_update_hp_label()
	add_to_group("enemy")

	attack_hitbox.set_deferred("monitoring", false)
	attack_hitbox.set_deferred("monitorable", false)
	attack_hitbox_shape.set_deferred("disabled", true)

	var detect_circle := detection_shape.shape as CircleShape2D
	if detect_circle != null:
		detect_circle.radius = aggro_range

	var attack_circle := attack_range_shape.shape as CircleShape2D
	if attack_circle != null:
		attack_circle.radius = attack_distance

	sprite.frame_changed.connect(_on_sprite_frame_changed)
	_find_player()
	_set_facing(facing_dir)
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	var was_walking := false
	var is_walking = absf(velocity.x) > 5.0 and not is_attacking and not is_hurt
	if is_walking and not was_walking:
		_play_step_loop()
	if not is_walking and was_walking:
		_stop_step_loop()
	was_walking = is_walking

	if is_dead:
		return

	if global_position.y > spawn_position.y + fall_respawn_distance:
		_respawn_at_spawn_position()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if not _is_player_valid():
		_find_player()

	if is_phase_shifting:
		velocity.x = 0.0
		move_and_slide()
		return

	if is_hurt:
		velocity.x = move_toward(velocity.x, 0.0, _get_current_move_speed())
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	if _has_target_in_aggro():
		_handle_combat_movement()
	else:
		velocity.x = move_toward(velocity.x, 0.0, _get_current_move_speed())
		if sprite.animation != "idle":
			sprite.play("idle")

	move_and_slide()
	
	if not is_dead and not is_attacking and not is_hurt:
		if absf(velocity.x) > 5.0:
			if sprite.animation != "walk":
				sprite.play("walk")
		elif sprite.animation != "idle":
			sprite.play("idle")

func _respawn_at_spawn_position() -> void:
	velocity = Vector2.ZERO
	global_position = spawn_position
	is_attacking = false
	is_hurt = false
	is_phase_shifting = false
	can_be_hurt = true
	hit_targets.clear()
	touch_targets.clear()
	_disable_attack_hitbox()
	_stop_step_loop()
	modulate = Color.WHITE
	if phase_label != null:
		phase_label.visible = false
	sprite.play("idle")

func take_damage(amount: int) -> void:
	if is_dead:
		return

	if is_attacking and super_armor_during_attack:
		current_health -= amount
		_update_hp_label()
		_update_phase_state()
		if current_health <= 0:
			_die()
		return

	if is_hurt or not can_be_hurt:
		return

	current_health -= amount
	_update_hp_label()
	_update_phase_state()

	if current_health <= 0:
		_die()
		return

	_interrupt_attack()
	can_be_hurt = false
	is_hurt = true
	sprite.play("hurt")
	await sprite.animation_finished
	if not is_inside_tree() or is_dead:
		return

	is_hurt = false
	await get_tree().create_timer(max(hurt_invuln_time, hurt_cooldown)).timeout
	if not is_inside_tree() or is_dead:
		return

	can_be_hurt = true

func _die() -> void:
	if is_dead:
		return

	is_dead = true
	if boss_music_playing:
		boss_music_playing = false
		Global.boss_music_changed.emit(false)
	_interrupt_attack()
	velocity = Vector2.ZERO
	body_shape.set_deferred("disabled", true)
	sprite.play("death")
	await sprite.animation_finished
	await get_tree().create_timer(death_linger_time).timeout
	if not is_inside_tree():
		return
	Global.finished_level = 1
	get_tree().change_scene_to_file("res://UI/win_screen.tscn")

func _handle_combat_movement() -> void:
	var dx := player.global_position.x - global_position.x
	var dir := signf(dx)
	if dir == 0.0:
		dir = facing_dir

	_set_facing(int(dir))

	if absf(dx) <= attack_distance:
		velocity.x = 0.0
		if can_attack:
			_start_attack()
		return

	velocity.x = dir * _get_current_move_speed()

func _start_attack() -> void:
	if is_attacking or not can_attack or is_dead:
		return

	_play_sound(slash_sound)
	is_attacking = true
	can_attack = false
	hit_targets.clear()
	velocity.x = 0.0
	sprite.play("attack")

	await sprite.animation_finished
	if not is_inside_tree() or is_dead:
		return

	_disable_attack_hitbox()
	is_attacking = false
	sprite.play("idle")

	await get_tree().create_timer(_get_current_attack_cooldown()).timeout
	if not is_inside_tree() or is_dead:
		return

	can_attack = true

func _interrupt_attack() -> void:
	_disable_attack_hitbox()
	is_attacking = false

func _enable_attack_hitbox() -> void:
	if hitbox_active:
		return

	hitbox_active = true
	attack_hitbox.set_deferred("monitoring", true)
	attack_hitbox.set_deferred("monitorable", true)
	attack_hitbox_shape.set_deferred("disabled", false)

func _disable_attack_hitbox() -> void:
	hitbox_active = false
	attack_hitbox.set_deferred("monitoring", false)
	attack_hitbox.set_deferred("monitorable", false)
	attack_hitbox_shape.set_deferred("disabled", true)

func _on_sprite_frame_changed() -> void:
	if not is_attacking or sprite.animation != "attack":
		return
	if sprite.animation == "walk":
		if sprite.frame == 1 or sprite.frame == 4:
			_play_sound(step_sound)

	if sprite.frame >= hit_active_from_frame and sprite.frame <= hit_active_to_frame:
		_enable_attack_hitbox()
	else:
		_disable_attack_hitbox()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if not is_attacking or not hitbox_active:
		return

	if not area.is_in_group("player_hurtbox"):
		return

	var target := area.get_parent()
	if target == null or not target.has_method("take_damage"):
		return

	var instance_id := target.get_instance_id()
	if hit_targets.has(instance_id):
		return

	hit_targets[instance_id] = true
	var knockback := Vector2(signf(target.global_position.x - global_position.x), -0.4)
	if knockback.x == 0.0:
		knockback.x = facing_dir
	target.take_damage(attack_damage, knockback.normalized())

func _on_touch_damage_area_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	if not area.is_in_group("player_hurtbox"):
		return

	var target := area.get_parent()
	if target == null or not target.has_method("take_damage"):
		return

	var instance_id := target.get_instance_id()
	if touch_targets.has(instance_id):
		return

	touch_targets[instance_id] = true
	var knockback := Vector2(signf(target.global_position.x - global_position.x), -0.2)
	if knockback.x == 0.0:
		knockback.x = facing_dir
	target.take_damage(touch_damage, knockback.normalized())

	_start_touch_cooldown(instance_id)

func _start_touch_cooldown(instance_id: int) -> void:
	await get_tree().create_timer(touch_damage_cooldown).timeout
	if not is_inside_tree():
		return

	touch_targets.erase(instance_id)

func _on_detection_area_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_in_group(player_group):
		player = body
		if not boss_music_playing:
			boss_music_playing = true
			Global.boss_music_changed.emit(true)

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player and not _has_target_in_aggro():
		player = null

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group(player_group)
	if players.size() > 0 and players[0] is CharacterBody2D:
		player = players[0] as CharacterBody2D

func _is_player_valid() -> bool:
	return is_instance_valid(player)

func _has_target_in_aggro() -> bool:
	if not _is_player_valid():
		return false

	return global_position.distance_to(player.global_position) <= aggro_range

func _update_phase_state() -> void:
	if not is_phase_two and current_health <= max_health * 0.5:
		is_phase_two = true
		_start_phase_shift("PHASE 2", Color(1.0, 0.85, 0.85), Color(0.882353, 0.294118, 0.172549, 1.0))

	if not is_phase_three and current_health <= max_health * phase_three_health_threshold:
		is_phase_three = true
		_start_phase_shift("FINAL PHASE", Color(1.0, 0.72, 0.72), Color(0.960784, 0.219608, 0.145098, 1.0))

func _get_current_move_speed() -> float:
	if is_phase_three:
		return phase_three_move_speed
	if is_phase_two:
		return phase_two_move_speed
	return move_speed

func _get_current_attack_cooldown() -> float:
	if is_phase_three:
		return phase_three_attack_cooldown
	if is_phase_two:
		return phase_two_attack_cooldown
	return attack_cooldown

func _set_facing(direction: int) -> void:
	if direction == 0:
		return

	facing_dir = direction
	$FlipRoot.scale.x = 1 if facing_dir > 0 else -1
	attack_hitbox.position.x = attack_hitbox_offset_x * facing_dir

func _start_phase_shift(phase_text: String, boss_tint: Color, hp_fill_color: Color) -> void:
	if is_dead:
		return

	is_phase_shifting = true
	velocity = Vector2.ZERO
	_disable_attack_hitbox()
	is_attacking = false
	is_hurt = false

	if boss_health_bar != null:
		var fill_style := boss_health_bar.get("theme_override_styles/fill") as StyleBoxFlat
		if fill_style != null:
			fill_style.bg_color = hp_fill_color

	if phase_label != null:
		phase_label.text = phase_text
		phase_label.visible = true

	_flash_phase_tint(boss_tint)

func _flash_phase_tint(target_tint: Color) -> void:
	modulate = Color.WHITE
	await get_tree().create_timer(0.08).timeout
	if not is_inside_tree() or is_dead:
		return

	modulate = target_tint
	await get_tree().create_timer(phase_shift_pause).timeout
	if not is_inside_tree() or is_dead:
		return

	if phase_label != null:
		phase_label.visible = false

	is_phase_shifting = false

func _update_hp_label() -> void:
	if hp_label != null:
		hp_label.text = "%d / %d" % [max(current_health, 0), max_health]

func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()

func _play_step_loop():
	if step_sound and not step_sound.playing:
		step_sound.play()

func _stop_step_loop():
	if step_sound and step_sound.playing:
		step_sound.stop()

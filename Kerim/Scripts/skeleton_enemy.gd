extends BaseEnemy
class_name SkeletonEnemy

@export var patrol_speed: float = 40.0
@export var chase_speed: float = 65.0
@export var retreat_speed: float = 80.0
@export var patrol_radius: float = 96.0
@export var aggro_range: float = 160.0
@export var ranged_attack_range: float = 220.0
@export var ranged_min_range: float = 48.0
@export var target_lock_range: float = 320.0
@export var fire_frame: int = 8
@export var arrow_damage: int = 12
@export var arrow_speed: float = 260.0
@export var arrow_fly_time: float = 1.3
@export var ranged_attack_cooldown: float = 1.6

# ↓ ENTFERNT: max_health, player_group, gravity, current_health, is_dead
# kommen alle von BaseEnemy!

@onready var sprite: AnimatedSprite2D = $FlipRoot/AnimatedSprite2D
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var ground_ray: RayCast2D = $GroundRayCast2D
@onready var wall_ray: RayCast2D = $WallRayCast2D
@onready var touch_hitbox: Area2D = $TouchHitbox
@onready var arrow: Area2D = $Arrow
@onready var arrow_collision: CollisionShape2D = $Arrow/CollisionShape2D
@onready var arrow_sprite: Sprite2D = $Arrow/Sprite2D
@onready var arrow_spawn: Marker2D = $FlipRoot/ArrowSpawn

@onready var shoot: AudioStreamPlayer = get_node_or_null("Sound/shoot")

var spawn_position := Vector2.ZERO
var facing_dir := -1
var patrol_dir := -1
var can_ranged_attack := true
var is_shooting := false
var arrow_flying := false
var arrow_direction := Vector2.LEFT
var waiting_for_fire_frame := false
var turn_cooldown := 0.0

func _ready() -> void:
	super._ready()  # ← BaseEnemy._ready() aufrufen
	spawn_position = global_position
	touch_hitbox.remove_from_group("enemy_hitbox")
	touch_hitbox.monitoring = false
	touch_hitbox.monitorable = false
	_update_sensor_setup()
	_reset_arrow()
	sprite.frame_changed.connect(_on_sprite_frame_changed)
	sprite.play("idle")

# ↓ on_death statt die() — BaseEnemy.die() ruft das auf
func on_death() -> void:
	is_shooting = false
	waiting_for_fire_frame = false
	velocity = Vector2.ZERO
	_reset_arrow()
	modulate = Color.WHITE
	sprite.play("death")
	await sprite.animation_finished
	queue_free()

# ↓ take_damage vereinfacht — BaseEnemy übernimmt health/death Logik
func take_damage(amount: int) -> void:
	if is_dead:
		return
	modulate = Color(1.0, 0.65, 0.65)
	super.take_damage(amount)  # ← BaseEnemy zieht HP ab und ruft die() auf
	_flash_back_to_default()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	turn_cooldown = maxf(0.0, turn_cooldown - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	if not _is_player_valid():
		_find_player()

	if arrow_flying:
		arrow.global_position += arrow_direction * arrow_speed * delta

	if is_shooting:
		velocity.x = move_toward(velocity.x, 0.0, chase_speed)
		move_and_slide()
		return

	if _has_target():
		_handle_target_movement()
	elif _is_player_valid():
		_hold_position()
	else:
		_patrol()

	move_and_slide()
	_update_animation()

func _patrol() -> void:
	if _should_turn_around() and turn_cooldown <= 0.0:
		_turn_around()
	elif abs(global_position.x - spawn_position.x) > patrol_radius and turn_cooldown <= 0.0:
		_turn_around()
	velocity.x = patrol_dir * patrol_speed
	_set_facing(patrol_dir)

func _has_target() -> bool:
	if not _is_player_valid():
		return false
	return global_position.distance_to(player.global_position) <= target_lock_range

func _handle_target_movement() -> void:
	var horizontal_distance := player.global_position.x - global_position.x
	var player_dir := signf(horizontal_distance)
	if player_dir == 0.0:
		player_dir = facing_dir
	_set_facing(int(player_dir))

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player <= ranged_min_range:
		_retreat_from_player(player_dir)
		return
	if distance_to_player <= ranged_attack_range:
		velocity.x = 0.0
		if can_ranged_attack:
			_start_ranged_attack()
		return
	_move_towards_shooting_range(player_dir)

func _retreat_from_player(player_dir: float) -> void:
	var move_dir := -player_dir
	if _blocked_in_direction(move_dir):
		velocity.x = 0.0
		return
	velocity.x = move_dir * retreat_speed

func _move_towards_shooting_range(player_dir: float) -> void:
	if _blocked_in_direction(player_dir):
		velocity.x = 0.0
		return
	velocity.x = player_dir * chase_speed

func _should_turn_around() -> bool:
	return is_on_floor() and (wall_ray.is_colliding() or not ground_ray.is_colliding())

func _turn_around() -> void:
	patrol_dir *= -1
	_set_facing(patrol_dir)
	turn_cooldown = 0.2

func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing_dir = direction
	$FlipRoot.scale.x = -1 if facing_dir > 0 else 1
	ground_ray.position.x = 10.0 * facing_dir
	wall_ray.target_position.x = 12.0 * facing_dir

func _hold_position() -> void:
	velocity.x = move_toward(velocity.x, 0.0, chase_speed)

func _blocked_in_direction(direction: float) -> bool:
	if direction == 0.0:
		return false
	var direction_sign := 1 if direction > 0.0 else -1
	var wall_blocked := wall_ray.is_colliding() and signf(wall_ray.target_position.x) == direction_sign
	var missing_ground := not ground_ray.is_colliding() and signf(ground_ray.position.x) == direction_sign
	return is_on_floor() and (wall_blocked or missing_ground)

func _start_ranged_attack() -> void:
	if is_shooting or is_dead or not _is_player_valid():
		return
	is_shooting = true
	can_ranged_attack = false
	waiting_for_fire_frame = true
	velocity.x = 0.0
	_set_facing(int(signf(player.global_position.x - global_position.x)))
	_play_sound(shoot)
	sprite.play("attack")
	await sprite.animation_finished
	if not is_inside_tree() or is_dead:
		return
	is_shooting = false
	waiting_for_fire_frame = false
	sprite.play("idle")
	await get_tree().create_timer(ranged_attack_cooldown).timeout
	if not is_inside_tree() or is_dead:
		return
	can_ranged_attack = true

func _spawn_arrow() -> void:
	arrow_direction = Vector2.RIGHT if facing_dir > 0 else Vector2.LEFT
	arrow.global_position = arrow_spawn.global_position
	arrow.rotation = arrow_direction.angle()
	arrow_sprite.flip_h = false
	arrow.monitoring = true
	arrow.monitorable = true
	arrow_collision.disabled = false
	arrow.visible = true
	arrow_flying = true
	get_tree().create_timer(arrow_fly_time).timeout.connect(_on_arrow_fly_timeout)

func _on_sprite_frame_changed() -> void:
	if not waiting_for_fire_frame or sprite.animation != "attack" or sprite.frame != fire_frame:
		return
	waiting_for_fire_frame = false
	_spawn_arrow()

func _on_arrow_area_entered(area: Area2D) -> void:
	if not arrow_flying:
		return
	if area.is_in_group("player_hurtbox"):
		var target := area.get_parent()
		if target != null and target.has_method("take_damage"):
			target.take_damage(arrow_damage, Vector2(arrow_direction.x, -0.2).normalized())
		_request_arrow_reset()
		return
	if not area.is_in_group("enemy_hitbox"):
		_request_arrow_reset()

func _on_arrow_body_entered(body: Node) -> void:
	if not arrow_flying or body.is_in_group(player_group):
		return
	_request_arrow_reset()

func _on_arrow_fly_timeout() -> void:
	if arrow_flying:
		_reset_arrow()

func _request_arrow_reset() -> void:
	if not arrow_flying:
		return
	arrow_flying = false
	arrow.visible = false
	arrow.global_position = Vector2(-999999, -999999)
	call_deferred("_reset_arrow")

func _reset_arrow() -> void:
	arrow_flying = false
	arrow.visible = false
	arrow.set_deferred("monitoring", false)
	arrow.set_deferred("monitorable", false)
	arrow_collision.set_deferred("disabled", true)
	arrow.global_position = arrow_spawn.global_position

func _on_detection_area_body_entered(body: Node) -> void:
	if body is CharacterBody2D and body.is_in_group(player_group):
		player = body

func _on_detection_area_body_exited(body: Node) -> void:
	if body == player:
		player = null

func _is_player_valid() -> bool:
	return is_instance_valid(player)

func _update_animation() -> void:
	if is_dead or is_shooting:
		return
	if absf(velocity.x) > 5.0:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _update_sensor_setup() -> void:
	var range_shape := detection_shape.shape as CircleShape2D
	if range_shape != null:
		range_shape.radius = max(aggro_range, ranged_attack_range)
	_set_facing(facing_dir)

func _flash_back_to_default() -> void:
	await get_tree().create_timer(0.1).timeout
	if is_inside_tree() and not is_dead:
		modulate = Color.WHITE
		
func _play_sound(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()

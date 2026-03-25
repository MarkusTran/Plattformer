extends BaseEnemy
class_name SlimeEnemy

@export var detection_range: float = 220.0
@export var jump_velocity: float = -300.0
@export var jump_cooldown: float = 0.9
@export var hop_speed: float = 140.0
@export var stand_off: float = 26.0
@export var max_hop_speed: float = 160.0
@export var hitbox_offset_x: float = 14.0
@export var knockback_force: float = 150.0  # ← Knockback beim Treffer

@onready var hitbox: Area2D = $Hitbox
@onready var flip_root: Node2D = $FlipRoot
@onready var anim: AnimatedSprite2D = $FlipRoot/AnimatedSprite2D

var jump_timer := 0.0
var is_hurt := false

func on_ready() -> void:
	hitbox.add_to_group("enemy_hitbox")
	anim.play("default")

func on_death() -> void:
	velocity = Vector2.ZERO
	# set_deferred verhindert bereits gefeuerte Signals
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	anim.play("death")
	await anim.animation_finished
	queue_free()

# Hit Flash + Knockback
func take_damage(amount: int) -> void:
	if is_dead or is_hurt:
		return
	
	# Knockback Richtung vom Player weg
	if player != null:
		var dir = sign(global_position.x - player.global_position.x)
		if dir == 0:
			dir = 1
		velocity.x = dir * knockback_force
		velocity.y = -100.0
	
	# Hit Flash
	modulate = Color(1.0, 0.3, 0.3)
	is_hurt = true
	
	super.take_damage(amount)  # ← BaseEnemy zieht HP ab
	
	await get_tree().create_timer(0.15).timeout
	if not is_inside_tree() or is_dead:
		return
	modulate = Color.WHITE
	is_hurt = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not player:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	jump_timer = max(0.0, jump_timer - delta)

	var dist = global_position.distance_to(player.global_position)
	if dist > detection_range:
		velocity.x = move_toward(velocity.x, 0, 600.0)
		move_and_slide()
		return

	if is_on_floor() and jump_timer <= 0.0:
		do_hop_towards_player()
		jump_timer = jump_cooldown

	update_anim_and_flip()
	move_and_slide()

func update_anim_and_flip() -> void:
	if velocity.x > 5:
		flip_root.scale.x = 1
	elif velocity.x < -5:
		flip_root.scale.x = -1
	if not is_dead and (anim.animation != "default" or not anim.is_playing()):
		anim.play("default")

func do_hop_towards_player() -> void:
	var dx = player.global_position.x - global_position.x
	var dir_x = sign(dx)
	if dir_x == 0:
		dir_x = 1
	var target_x = player.global_position.x - dir_x * stand_off
	var t = (2.0 * abs(jump_velocity)) / gravity
	t = max(t, 0.18)
	var needed_vx = (target_x - global_position.x) / t
	needed_vx = clamp(needed_vx, -max_hop_speed, max_hop_speed)
	if abs(dx) < stand_off:
		needed_vx = 0.0
	velocity.y = jump_velocity
	velocity.x = needed_vx

#MainPlayer

extends CharacterBody2D

# Input actions
const MOVE_RIGHT_ACTION := "move_right"
const MOVE_LEFT_ACTION  := "move_left"
const JUMP_ACTION       := "ui_accept"
const SHOOT_ACTION      := "shoot"
const INTERACT          := "interact"

@export var speed: float = 240.0
@export var coins: int = 0
@export var health : float = 100.0

# Export Variablen oben hinzufügen:
@export var max_health: int = 100
@export var invincible_time: float = 0.4
@export var knockback_x: float = 260.0
@export var knockback_y: float = 180.0
@export var knockback_lock: float = 0.18
@export var touch_damage: int = 10
@export var dead_state: State 

var current_health: int
var invincible := false
var is_dead := false
var kb_time := 0.0

@onready var hurtbox: Area2D = $Hurtbox

var down_acceleration: float = 1.0
var direction := Vector2.ZERO

@onready var state_machine: CharacterStateMachine = $CharacterStateMachine
@onready var sprite2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var coinLabel: Label = $"Camera2D/UI/Control/VBoxContainer/HBoxContainer2/Coin"
@onready var HealthLabel: Label = $"Camera2D/UI/Control/VBoxContainer/HBoxContainer/HP"
@onready var interactLabel: Label = $"Interaction Components/Label"
@onready var all_interactions: Array = []
@onready var LoosingPanel: Panel = $"Camera2D/UI/Control/VBoxContainer/Loosing"

#Attack
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

@export var attack_damage: int = 30
var already_hit := {}


func _ready() -> void:
	Global.playerBody = self
	current_health = Global.current_health
	max_health = Global.max_health
	coins = Global.coins
	attack_damage = Global.attack_damage
	LoosingPanel.hide()
	_update_Hud()
	
	if hurtbox != null:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	else:
		push_error("Hurtbox Node nicht gefunden!")
	
	# body_entered statt area_entered!
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.disabled = true
	update_interaction()
	_update_Hud()

func _update_Hud() -> void:
	coinLabel.text = "Coin: %s" % coins
	HealthLabel.text = "%s / %s" % [current_health, max_health]

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if kb_time > 0.0:
		kb_time -= delta
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if Input.is_action_just_pressed(INTERACT):
		execute_interaction()

	if not is_on_floor():
		velocity += get_gravity() * delta * down_acceleration

	# ← Nur X-Achse für Bewegung, Y separat für Facing
	var move_x := Input.get_axis("move_left", "move_right")
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if move_x != 0 and state_machine.check_if_can_move():
		velocity.x = move_x * speed  # ← immer volle speed, kein diagonal penalty
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	update_facing_direction()
	move_and_slide()


func update_facing_direction() -> void:
	if direction.x > 0:
		sprite2d.flip_h = false
	elif direction.x < 0:
		sprite2d.flip_h = true

# --- Interactions ---
func _on_interaction_area_area_entered(area: Area2D) -> void:
	all_interactions.insert(0, area)
	update_interaction()

func _on_interaction_area_area_exited(area: Area2D) -> void:
	all_interactions.erase(area)
	update_interaction()

func update_interaction() -> void:
	if interactLabel == null:
		return
	if all_interactions:
		interactLabel.text = all_interactions[0].interact_label
		interactLabel.show()
	else:
		interactLabel.text = ""
		interactLabel.hide()

func execute_interaction() -> void:
	if all_interactions.is_empty():
		return
	var cur_interaction = all_interactions[0]
	match cur_interaction.interact_type:
		"print_text":
			print(cur_interaction.interact_value)
		"chest":
			var chest = cur_interaction.get_parent()
			if chest.has_method("interact"):
				chest.interact(self)
		"portal":
			var portal = cur_interaction.get_parent()
			if portal.has_method("interact"):
				
				Global.current_health = current_health
				Global.coins = coins
				Global.finished_level = Global.finished_level + 1
				
				portal.interact(self)

# --- Economy ---
func add_coins(amount: int) -> void:
	coins += amount
	_update_Hud()
	
# Diese Funktionen 1:1 von Kerim übernehmen:
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead or not area.is_in_group("enemy_hitbox"):
		return
	var enemy := area.get_parent()
	
	# ← Enemy bereits tot? Ignorieren!
	if enemy.has_method("is_dead") or "is_dead" in enemy:
		if enemy.is_dead:
			return
	
	var char_enemy := enemy as CharacterBody2D
	if char_enemy == null:
		return
	var dangerous: bool = (
		not char_enemy.is_on_floor()
		or abs(char_enemy.velocity.x) >= 30
		or char_enemy.velocity.y > 40
	)
	if not dangerous:
		return
	take_damage(touch_damage, _get_knockback_dir_from_position(area.global_position))
	
func _get_knockback_dir_from_position(from_pos: Vector2) -> Vector2:
	var dir_x: float = sign(global_position.x - from_pos.x)
	if dir_x == 0:
		dir_x = 1.0
	return Vector2(dir_x, -0.7).normalized()

func apply_knockback_dir(dir: Vector2) -> void:
	kb_time = knockback_lock
	var final_dir := dir if dir != Vector2.ZERO else Vector2(1, -0.7)
	final_dir = final_dir.normalized()
	velocity.x = final_dir.x * knockback_x
	velocity.y = -abs(knockback_y)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if invincible or is_dead:
		return
	invincible = true
	current_health -= amount
	#print("Player nimmt ", amount, " Schaden! Health: ", current_health)
	_update_Hud()
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
	
	LoosingPanel.show()
	state_machine.switch_states(dead_state)  # ← statt reload_current_scene
	
# Attack


func enable_attack_hitbox() -> void:
	already_hit.clear()
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	attack_shape.disabled = false
func end_attack() -> void:
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	attack_shape.disabled = true

func _on_attack_hitbox_body_entered(body: Node) -> void:
	if body == self:
		return
	if not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if already_hit.has(id):
		return
	already_hit[id] = true
	body.take_damage(attack_damage)
	
func _on_restart_pressed() -> void:
	# Global resetten
	Global.coins = 0
	Global.current_health = 100
	Global.max_health = 100
	Global.attack_damage = 30
	
	# Level 1 laden
	get_tree().change_scene_to_file("res://Levels/level_1.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

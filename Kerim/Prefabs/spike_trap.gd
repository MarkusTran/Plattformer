extends Node2D
class_name SpikeTrap

@export var damage: int = 20
@export var active_time: float = 1.0
@export var reset_time: float = 1.0
@export var retrigger_delay: float = 0.2

var is_active: bool = false
var is_busy: bool = false
var player_in_trigger: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var damage_area: Area2D = $DamageArea
@onready var damage_shape: CollisionShape2D = $DamageArea/CollisionShape2D

func _ready() -> void:
	damage_shape.set_deferred("disabled", true)

	trigger_area.body_entered.connect(_on_trigger_body_entered)
	trigger_area.body_exited.connect(_on_trigger_body_exited)

	damage_area.area_entered.connect(_on_damage_area_entered)

	anim.play("idle")

func _on_trigger_body_entered(body: Node) -> void:
	print("Trigger body entered: ", body.name)

	if not body.is_in_group("player"):
		return

	player_in_trigger = true

	if not is_busy:
		activate_trap()

func _on_trigger_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_in_trigger = false

func activate_trap() -> void:
	is_busy = true
	is_active = true

	anim.play("active")
	damage_shape.set_deferred("disabled", false)

	await get_tree().process_frame

	for area in damage_area.get_overlapping_areas():
		if area.name == "Hurtbox":
			var player := area.get_parent()
			if player != null and player.is_in_group("player"):
				_deal_damage(player)

	await get_tree().create_timer(active_time).timeout

	is_active = false
	damage_shape.set_deferred("disabled", true)
	anim.play("idle")

	await get_tree().create_timer(reset_time).timeout
	is_busy = false

	if player_in_trigger:
		await get_tree().create_timer(retrigger_delay).timeout
		if player_in_trigger and not is_busy:
			activate_trap()

func _on_damage_area_entered(area: Area2D) -> void:
	print("Damage area entered by area: ", area.name)

	if not is_active:
		return

	if area.name != "Hurtbox":
		return

	var player := area.get_parent()
	if player == null:
		return

	if not player.is_in_group("player"):
		return

	_deal_damage(player)

func _deal_damage(player: Node) -> void:
	print("Deal damage an: ", player.name)

	if player.has_method("take_damage"):
		var knockback_dir: Vector2

		if player.global_position.x < global_position.x:
			knockback_dir = Vector2(-1, -0.6)
		else:
			knockback_dir = Vector2(1, -0.6)

		player.take_damage(damage, knockback_dir)

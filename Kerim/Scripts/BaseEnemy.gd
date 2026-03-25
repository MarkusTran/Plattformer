extends CharacterBody2D
class_name BaseEnemy

@export var max_health: int = 60
@export var coin_drop: int = 5
@export var player_group: String = "player"

var current_health: int
var is_dead := false
var player: CharacterBody2D

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")
	call_deferred("_find_player")
	on_ready()  # ← Subklassen können das überschreiben

func on_ready() -> void:
	pass  # Override in Subklasse

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group(player_group)
	if players.size() > 0:
		player = players[0] as CharacterBody2D

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	on_hit()  # ← Subklasse kann Hurt Animation etc. machen
	if current_health <= 0:
		die()

func on_hit() -> void:
	pass  # Override in Subklasse

func die() -> void:
	if is_dead:
		return
	is_dead = true
	drop_coins()
	on_death()  # ← Subklasse macht Animation + queue_free

func on_death() -> void:
	queue_free()  # Default — Subklasse überschreibt für Animation

func drop_coins() -> void:
	# Direkt zum Player geben statt Global
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node = players[0]
		if player_node.has_method("add_coins"):
			player_node.add_coins(coin_drop)
			return
	# Fallback falls Player nicht gefunden
	Global.coins += coin_drop

extends Area2D

@export var damage: int = 20

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	# Nächsten Checkpoint finden
	var checkpoint = get_tree().get_first_node_in_group("active_checkpoint")
	if checkpoint == null:
		checkpoint = get_tree().get_first_node_in_group("checkpoint")
	
	# Schaden + Teleport
	body.take_damage(damage)
	body.global_position = checkpoint.global_position
	body.velocity = Vector2.ZERO

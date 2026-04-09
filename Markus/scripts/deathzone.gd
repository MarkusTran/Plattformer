extends Area2D

@export var damage: int = 20

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	
	var checkpoint = get_tree().get_first_node_in_group("active_checkpoint")
	if checkpoint == null:
		checkpoint = get_tree().get_first_node_in_group("checkpoint")
	if checkpoint == null:
		push_warning("Kein Checkpoint in der Szene!")
		return
	
	# Erst teleportieren, dann Schaden anwenden
	body.global_position = checkpoint.global_position
	body.velocity = Vector2.ZERO
	body.take_damage(damage)

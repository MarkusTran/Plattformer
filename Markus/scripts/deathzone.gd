extends Area2D

@export var damage: int = 20

func _ready() -> void:
	#body_entered.connect(_on_body_entered)
	print("DeathZone bereit")

func _on_body_entered(body: Node) -> void:
	print("Body entered DeathZone: ", body.name)
	if not body.is_in_group("player"):
		print("Kein Player - ignoriert")
		return
	
	print("Player in DeathZone!")
	var checkpoint = get_tree().get_first_node_in_group("active_checkpoint")
	if checkpoint == null:
		checkpoint = get_tree().get_first_node_in_group("checkpoint")
	
	if checkpoint == null:
		print("Kein Checkpoint gefunden!")
		return
		
	print("Checkpoint gefunden: ", checkpoint.name)
	body.take_damage(damage)
	body.global_position = checkpoint.global_position
	body.velocity = Vector2.ZERO

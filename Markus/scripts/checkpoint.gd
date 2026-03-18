extends Node2D

@onready var area: Area2D = $Area2D

func _ready() -> void:
	add_to_group("checkpoint")
	area.body_entered.connect(_on_body_entered)

func activate() -> void:
	for cp in get_tree().get_nodes_in_group("active_checkpoint"):
		cp.remove_from_group("active_checkpoint")
	add_to_group("active_checkpoint")
	print("Checkpoint aktiviert: ", name)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		activate()

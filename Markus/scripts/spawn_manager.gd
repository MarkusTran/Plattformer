extends Node2D

@export var enemy_scene: PackedScene
@onready var collision_shape = $Area2D/CollisionShape2D

func _on_timer_timeout():
	spawn_object()

func spawn_object():
	var rect_shape = collision_shape.shape as RectangleShape2D
	var extents = rect_shape.size / 2
	var center = collision_shape.global_position

	# Generate random local position
	var random_x = randf_range(-extents.x, extents.x)
	var random_y = randf_range(-extents.y, extents.y)

	# Instantiate
	var enemy = enemy_scene.instantiate()
	enemy.global_position = center + Vector2(random_x, random_y)
	get_tree().current_scene.add_child(enemy)

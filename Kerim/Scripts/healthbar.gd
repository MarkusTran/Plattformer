extends ProgressBar

@export var target: CharacterBody2D

func _ready():
	if target:
		max_value = target.max_health
		value = target.current_health

func _process(delta):
	if target:
		value = target.current_health

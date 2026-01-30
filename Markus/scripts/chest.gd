extends Node2D

@export var coins: int = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var opened := false

func interact(player):
	if opened:
		return

	opened = true
	open_chest()
	give_loot(player)

func open_chest():
	sprite.play("open")
	sprite.stop()
	# oder:
	# sprite.texture = preload("res://chest_open.png")

func give_loot(player):
	#player.add_coins(coins)
	pass

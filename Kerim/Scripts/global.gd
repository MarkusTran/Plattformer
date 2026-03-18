extends Node

var playerBody: CharacterBody2D = null

# Persistente Daten zwischen Levels
var coins: int = 0
var current_health: int = 100
var max_health: int = 100
var attack_damage: int = 20

var finished_level:int = 1

extends Control

# In ShopMenu.gd
@onready var gold_label: Label = $"VBoxContainer/Panel/HBoxContainer/MarginContainer/SHOP/HBoxContainer/Coin"
@onready var next_button: Button = $"VBoxContainer/Panel/MarginContainer2/PanelContainer/Next"


func _ready() -> void:
	_update_gold_display()
	next_button.pressed.connect(_on_next_pressed)
	
	# Direkt GridContainer Kinder connecten
	for item in $VBoxContainer/Panel/MarginContainer/GridContainer.get_children():
		if item.has_signal("item_purchased"):
			item.item_purchased.connect(_update_gold_display)

func _update_gold_display() -> void:
	gold_label.text = "Gold: %s" % Global.coins
	print("Gold Display updated: ", Global.coins)  # Debug
	

func _on_next_pressed() -> void:
	_add_a_scene_manually()
	
	
var scene_folder = "res://Levels/"

func _add_a_scene_manually():
	# This is like autoloading the scene, only
	# it happens after already loading the main scene.
	
	var full_path = scene_folder +"level_%s.tscn" %Global.finished_level
	var scene_tree = get_tree()
	if ResourceLoader.exists(full_path):
		scene_tree.change_scene_to_file(full_path)
	else:
		scene_tree.change_scene_to_file("res://UI/win_screen.tscn")

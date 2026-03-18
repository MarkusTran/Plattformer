extends Button

enum ItemType { HEAL, DMG_UP, MAX_HP_UP }

@export var item_type: ItemType = ItemType.HEAL
@export var item_title: String = "HP UP"
@export var item_price: int = 10
@export var item_value: int = 20  # wie viel geheilt/erhöht wird
@export var item_texture: Texture2D  # ← Im Editor Bild zuweisen


@onready var title_label: Label = $MarginContainer/HBoxContainer/title
@onready var price_label: Label = $MarginContainer/HBoxContainer/price
@onready var item_icon: TextureRect = $MarginContainer/HBoxContainer/VBoxContainer/TextureRect
@onready var value_label: Label = $"MarginContainer/HBoxContainer/VBoxContainer/VALUE"
# In shop_item.gd:
signal item_purchased

func _ready() -> void:
	if item_texture:
		item_icon.texture = item_texture
	title_label.text = item_title
	price_label.text = "%s Gold" % item_price
	value_label.text = "%s" % item_value
	pressed.connect(_on_pressed)
	

func _on_pressed() -> void:
	if Global.coins < item_price:
		print("Nicht genug Gold! Coins:", Global.coins, " Preis:", item_price)
		return
	
	Global.coins -= item_price
	
	match item_type:
		ItemType.HEAL:
			Global.current_health = min(Global.current_health + item_value, Global.max_health)
		ItemType.DMG_UP:
			Global.attack_damage += item_value
		ItemType.MAX_HP_UP:
			Global.max_health += item_value
			Global.current_health += item_value
	
	item_purchased.emit()  # ← Signal senden
	disabled = true
	modulate = Color(0.5, 0.5, 0.5)
	
	

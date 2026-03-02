extends CharacterBody2D

class_name GoblinEnemy

const speed = 30
var is_goblin_chase: bool = true

var health = 80
var health_max = 80
var health_min = 0

var dead: bool = false
var taking_damage: bool = false
var damage_to_deal = 20
var is_dealing_damage: bool = false

var dir : Vector2
const gravitiy = 900
var knockback_force = 200
var is_roaming: bool = true

var player_in_area = false

# Player wird nicht mehr im Inspektor zugewiesen, sondern über Global geholt
@export var player: CharacterBody2D # Das @export erlaubt dir, den Player im Editor in den Slot zu ziehen

func _ready() -> void:
	# Hier holen wir uns den Player, der sich in seiner eigenen _ready() Funktion in Global registriert hat
	player = Global.playerBody

func _process(delta: float):
	if !is_on_floor():
		velocity.y += gravitiy * delta
		velocity.x = 0
	
	# Global.goblinDamageAmount... Zeilen WURDEN GELÖSCHT. Brauchst du mit deinem System nicht!
	
	move(delta)
	handle_animation()
	move_and_slide()

func move(delta):
	# Wichtig: Prüfen ob der player existiert, um Abstürze zu vermeiden
	if !dead and player != null:
		if !is_goblin_chase:
			velocity += dir * speed * delta
		elif is_goblin_chase and !taking_damage:
			var dir_to_player = position.direction_to(player.position) * speed
			velocity.x = dir_to_player.x
			if velocity.x != 0:
				dir.x = abs(velocity.x) / velocity.x
		elif taking_damage:
			var knockback_dir = position.direction_to(player.position) * knockback_force
			velocity.x = -knockback_dir.x # Minus hinzugefügt, damit er vom Player WEG fliegt
		is_roaming = true
	elif dead:
		velocity.x = 0

func handle_animation():
	var anim_sprite = $AnimatedSprite2D
	if !dead and !taking_damage and !is_dealing_damage:
		anim_sprite.play("walk")
		if dir.x == -1:
			anim_sprite.flip_h = true
		elif dir.x == 1:
			anim_sprite.flip_h = false
	elif !dead and taking_damage and !is_dealing_damage:
		anim_sprite.play("hurt")
		await get_tree().create_timer(0.6).timeout
		taking_damage = false
	elif dead and is_roaming:
		is_roaming = false
		anim_sprite.play("death")
		await get_tree().create_timer(1.0).timeout
		handle_death()
	elif !dead and is_dealing_damage:
		anim_sprite.play("deal_damage")

func handle_death():
	self.queue_free()

func _on_direction_timer_timeout() -> void:
	$DirectionTimer.wait_time = choose([1.5, 2.0, 2.5])
	if !is_goblin_chase:
		dir = choose([Vector2.RIGHT, Vector2.LEFT])
		velocity.x = 0

func choose(array):
	array.shuffle()
	return array.front()

# Diese Funktion wird DIREKT von deinem "player_kerim.gd" Skript in der Zeile "body.take_damage(attack_damage)" aufgerufen!
# Die alte _on_goblin_hitbox_area_entered Funktion wurde gelöscht, da sie Konflikte verursacht hat.
func take_damage(damage):
	health -= damage
	taking_damage = true
	if health <= health_min:
		health = health_min
		dead = true
	print(str(self), " current health is: ", health)


func _on_goblin_deal_damage_area_area_entered(area: Area2D) -> void:
	# Wir prüfen direkt, ob die getroffene Area die Hurtbox des Players ist
	if player != null and area == player.hurtbox:
		is_dealing_damage = true
		
		# Wir rufen direkt die take_damage Funktion beim Player auf
		player.take_damage(damage_to_deal)
		
		# Kleiner Cooldown für die Animation
		await get_tree().create_timer(1.0).timeout
		is_dealing_damage = false

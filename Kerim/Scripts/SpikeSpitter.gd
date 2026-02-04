extends Node2D

@onready var arrow: Area2D = $Arrow
@onready var spitter: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $AnimatedSprite2D/Marker2D

@export var arrow_speed: float = 350.0
@export var shoot_left: bool = true
@export var muzzle_offset: Vector2 = Vector2.ZERO

@export var shoot_anim: StringName = &"default"
@export var fire_frame: int = 9          # Frame wo "Release" ist
@export var cooldown: float = 1.5        # Pause zwischen Schüssen
@export var arrow_fly_time: float = 1.0  # wie lange der Pfeil fliegt (danach despawn)

@export var damage := 15
@export var knockback := 300.0

var direction := Vector2.LEFT
var flying := false
var waiting_for_fire_frame := false

func _ready() -> void:
	# Richtung + Optik
	if shoot_left:
		spitter.flip_h = false
		direction = Vector2.LEFT
	else:
		spitter.flip_h = true
		direction = Vector2.RIGHT

	# echter Pfeil ist nur sichtbar, wenn er fliegt
	arrow.visible = false
	flying = false

	# Frame-genaues Feuern
	spitter.frame_changed.connect(_on_spitter_frame_changed)
	arrow.area_entered.connect(_on_arrow_area_entered)
	# Intervall-Schießen starten (Loop)
	_shoot_loop()


func _physics_process(delta: float) -> void:
	if flying:
		arrow.global_position += direction * arrow_speed * delta

func _on_arrow_area_entered(area: Area2D) -> void:
	if not flying:
		return
	if not area.is_in_group("player_hurtbox"):
		return

	var player := area.get_parent()
	if player.has_method("take_damage"):
		player.take_damage(damage)

	_despawn_arrow()



# ---------------------------
# Haupt-Loop: schießen -> warten -> schießen ...
# ---------------------------
func _shoot_loop() -> void:
	while is_inside_tree():
		# 1) Animation starten und auf Fire-Frame warten
		waiting_for_fire_frame = true
		spitter.play(shoot_anim)

		# warten bis der Pfeil wirklich gespawnt wurde
		while waiting_for_fire_frame and is_inside_tree():
			await get_tree().process_frame

		# 2) Pfeil fliegt für arrow_fly_time
		await get_tree().create_timer(arrow_fly_time).timeout
		_despawn_arrow()

		# 3) Cooldown/Pause
		await get_tree().create_timer(cooldown).timeout


func _on_spitter_frame_changed() -> void:
	if not waiting_for_fire_frame:
		return
	if spitter.animation != shoot_anim:
		return

	if spitter.frame == fire_frame:
		_spawn_and_shoot()


func _spawn_and_shoot() -> void:
	waiting_for_fire_frame = false
	flying = true

	# Kollision aktivieren
	arrow.set_deferred("monitoring", true)
	arrow.set_deferred("monitorable", true)

	arrow.visible = true
	arrow.global_position = muzzle.global_position + muzzle_offset # falls du offset nutzt
	arrow.rotation = direction.angle() + PI # falls du +PI brauchst


func _despawn_arrow() -> void:
	flying = false
	arrow.visible = false
	arrow.global_position = muzzle.global_position

	# Wichtig: Kollision deaktivieren
	arrow.set_deferred("monitoring", false)
	arrow.set_deferred("monitorable", false)

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




var despawn_queued := false

var flying := false
var needs_reset := false
var direction := Vector2.LEFT
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

	if needs_reset:
		_do_reset()


func _on_arrow_area_entered(area: Area2D) -> void:
	if not flying:
		return

	if area.is_in_group("player_hurtbox"):
		var player := area.get_parent()
		if player and player.has_method("take_damage"):
			player.take_damage(damage)
		needs_reset = true
		return

	if area.is_in_group("arrow_stop"):
		needs_reset = true
		return

func _do_reset() -> void:
	needs_reset = false
	flying = false

	arrow.visible = false
	arrow.monitoring = false   # JETZT ist es erlaubt
	arrow.global_position = muzzle.global_position



func reset_arrow() -> void:
	# Bewegung sofort stoppen
	flying = false

	# Pfeil "weg"
	arrow.visible = false

	# Ganz wichtig: KEIN monitoring hier anfassen!
	# Nur Position zurücksetzen
	arrow.global_position = muzzle.global_position



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
		request_despawn()


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

	arrow.global_position = muzzle.global_position + muzzle_offset
	arrow.rotation = direction.angle() + PI

	arrow.monitoring = true
	arrow.visible = true
	flying = true


	
func request_despawn() -> void:
	if despawn_queued:
		return
	despawn_queued = true

	flying = false
	arrow.visible = false

	# SOFORT raus aus allem (damit keine Overlaps mehr stattfinden)
	arrow.global_position = Vector2(-999999, -999999)

	call_deferred("_despawn_arrow_deferred")

	
func _despawn_arrow_deferred() -> void:
	arrow.monitoring = false
	arrow.monitorable = false
	arrow.global_position = muzzle.global_position
	despawn_queued = false

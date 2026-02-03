extends Node2D

@onready var arrow: Area2D = $Arrow
@onready var spitter: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzle: Marker2D = $AnimatedSprite2D/Marker2D

@export var arrow_speed: float = 350.0
@export var shoot_interval: float = 2.0
@export var shoot_left: bool = true


@export var shoot_anim: StringName = &"default"
@export var fire_frame: int = 9 # <<< HIER: Frame, auf dem der Pfeil "losgeht"

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

	# Wichtig: echter Pfeil ist unsichtbar, bis er wirklich abgeschossen wird
	arrow.visible = false
	flying = false

	# Frame-genaues Feuern
	spitter.frame_changed.connect(_on_spitter_frame_changed)
	spitter.animation_finished.connect(_on_spitter_animation_finished)

	start_auto_fire()


func _physics_process(delta: float) -> void:
	if flying:
		arrow.global_position += direction * arrow_speed * delta


func start_auto_fire() -> void:
	var t := Timer.new()
	t.wait_time = shoot_interval
	t.autostart = true
	add_child(t)
	t.timeout.connect(_on_fire_timer_timeout)


func _on_fire_timer_timeout() -> void:
	if flying or waiting_for_fire_frame:
		return

	waiting_for_fire_frame = true

	var anim: StringName = shoot_anim
	if anim == StringName(""): # leer
		anim = &"default"

	spitter.play(anim)


func _on_spitter_frame_changed() -> void:
	if not waiting_for_fire_frame:
		return

	if spitter.animation != shoot_anim:
		return

	if spitter.frame == fire_frame:
		# GENAU hier schießen
		_spawn_and_shoot()


func _spawn_and_shoot() -> void:
	waiting_for_fire_frame = false
	flying = true

	arrow.visible = true
	arrow.global_position = muzzle.global_position
	arrow.rotation = direction.angle()


func _on_spitter_animation_finished() -> void:
	# optional: nach der Schuss-Animation stehen bleiben
	# spitter.stop()
	pass

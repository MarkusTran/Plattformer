extends CharacterBody2D

# Input actions
const MOVE_RIGHT_ACTION := "move_right"
const MOVE_LEFT_ACTION  := "move_left"
const JUMP_ACTION       := "ui_accept"
const SHOOT_ACTION      := "shoot"
const INTERACT := "interact"


@export var start_x: float = 482.0
@export var start_y: float = 531.0
@export var speed: float = 120.0
@export var jump_velocity: float = -350.0
@export var double_jump_velocity: float = -350
@export var laser_prefab: PackedScene
@onready var state_machine : CharacterStateMachine = $CharacterStateMachine

var down_acceleration: float = 1.0
var has_double_jump: bool = false

@onready var sprite2d : Sprite2D = $Sprite2D
@onready var all_interactions = []
@onready var interactLabel =$"Interaction Components/Label"

@onready var animation_tree : AnimationTree = $AnimationTree

var direction = Input.get_vector("move_left","move_right","move_up","move_down")



func _ready() -> void:
	update_interaction()
	position = Vector2(start_x, start_y)
	animation_tree.active = true

func _physics_process(delta: float) -> void:
	#Input handeling
	if Input.is_action_just_pressed(INTERACT):
		execute_interaction()
	
	# Jump
	if Input.is_action_just_pressed(JUMP_ACTION):
		if is_on_floor():
			pass
		elif not has_double_jump:
			velocity.y = double_jump_velocity
			#double jump in air
	
	#Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta * down_acceleration
	else:
		has_double_jump = false
	
	if direction.x != 0 && state_machine.check_if_can_move():
			velocity.x = direction.x * speed
	else:
		velocity.x = move_toward(velocity.x,0,speed)
		
	direction = Input.get_vector("move_left","move_right","move_up", "move_down")
	
	

	update_facing_direction()
	update_animation()
	move_and_slide()

func update_animation():
	animation_tree.set("parameters/Move/blend_position",direction.x)

func damage_taken() -> void:
	print("Player took damage")


###Interactions

func _on_interaction_area_area_entered(area: Area2D) -> void:
	all_interactions.insert(0,area)
	update_interaction()

func _on_interaction_area_area_exited(area: Area2D) -> void:
	all_interactions.erase(area)
	update_interaction()
	
func update_facing_direction():
	if direction.x > 0:
		sprite2d.flip_h = false
	elif direction.x < 0:
		sprite2d.flip_h = true
	
func update_interaction():
	if all_interactions:
		interactLabel.text = all_interactions[0].interact_label;
	else:
		interactLabel.text = ""
		
func execute_interaction():
	if all_interactions:
		
		var cur_interaction = all_interactions[0]
		match cur_interaction.interact_type:
			"print_text" : print(cur_interaction.interact_value)

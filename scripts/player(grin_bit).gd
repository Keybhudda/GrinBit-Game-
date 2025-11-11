extends CharacterBody2D
#Grin Bit Code Below
const GRID_SIZE = 16
var speed = 4.5
var direction = Vector2.ZERO
var next_direction = Vector2.ZERO
var moving = false
var target_pos = Vector2.ZERO

@export var default_mode: Mode = Mode.NORM

enum Mode {NORM, EAT}
var mode: Mode = Mode.NORM

var current_mode: Mode = Mode.NORM

@onready var norm: Sprite2D = $Norm
@onready var eat_mode: Sprite2D = $EatMode



@export var map: TileMapLayer

signal Start_Position(entity_name: String, position: Vector2)

func _ready(): 
	#snap player to grid at start
	@warning_ignore("integer_division")
	position = map.map_to_local(map.local_to_map(position)).snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	target_pos = position
	@warning_ignore("integer_division")
	if position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2)):
		set_mode(Mode.NORM)
		emit_signal("Start_Position", name, position)


func stop_movement() -> void:
	velocity = Vector2.ZERO
	moving = false
	@warning_ignore("integer_division")
	position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	print(name, " Has Stopped All Movement.")

#For chaning and setting Modes for this character
func set_mode(new_mode: Mode):
	if current_mode != new_mode:
		current_mode = new_mode
		mode = new_mode
		print(name, "mode switched to:", new_mode)
		update_look(new_mode)


func update_look(new_mode: Mode) -> void:
	match new_mode:
		Mode.NORM:
			norm.visible = true
		Mode.EAT:
			norm.visible = false

func _physics_process(_delta):
	
	handle_input()
	if moving: 
		#move towards target tile
		position = position.move_toward(target_pos, speed * GRID_SIZE * _delta)
		
		
		#stop moving when reach target tile
		if position.distance_to(target_pos) < 0.1:
			@warning_ignore("integer_division")
			position = target_pos.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
			moving = false
			
			
			#Check if we can change direction while moving
			if next_direction != Vector2.ZERO and can_move(next_direction):
				start_move(next_direction)
			elif can_move(direction):
				start_move(direction)
	else: 
		#If not moving, try next direction if possible
		if next_direction != Vector2.ZERO and can_move(next_direction):
			start_move(next_direction)
		elif  direction != Vector2.ZERO and can_move(direction):
			start_move(direction)
	
	#check if wall is hitting 

#How The Player Move Grinbit
func handle_input():
	if Input.is_action_pressed("ui_up"):
		next_direction = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		next_direction = Vector2.DOWN
	elif Input.is_action_pressed("ui_left"):
		next_direction = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		next_direction = Vector2.RIGHT


func start_move(dir: Vector2):
	direction = dir
	@warning_ignore("integer_division")
	target_pos = (position + direction * GRID_SIZE).snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	moving = true

func can_move(dir: Vector2) -> bool:
	@warning_ignore("integer_division")
	var _current_position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	@warning_ignore("integer_division")
	var test_pos = (_current_position + dir * GRID_SIZE).snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	
	var space_state = get_world_2d().direct_space_state
	#parmaters for query 
	var params = PhysicsPointQueryParameters2D.new()
	params.position = test_pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	#Only Check walls and eneimes (layer 1)
	params.collision_mask = 1 << 0
	
	if mode == Mode.EAT:
		params.collide_with_areas = false
	
	
	return space_state.intersect_point(params).is_empty()
#need to improve collideing when in EAT Mode for smoother enemy collection.

func on_enter_run_mode():
	#Called when chase mode starts
	set_mode(Mode.EAT)
	speed = 5

func on_exit_run_mode():
	#Called when chase mode ends
	set_mode(default_mode)
	speed = 4.5

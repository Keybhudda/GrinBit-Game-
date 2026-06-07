extends CharacterBody2D
#----------------------Scene and Other Node Connections ------------------------

@onready var norm: Sprite2D = $Norm
@onready var eat_mode: Sprite2D = $EatMode
@export var map: TileMapLayer
#----------------------Based Variables & Modes----------------------------------
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

const TURN_EARLY_DISTANCE := 16.0

var _last_direction := Vector2.ZERO
#----------------------Start Code ----------------------------------------------
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

#Funtion Stops player movment to prevent going off grid
func stop_movement() -> void:
	velocity = Vector2.ZERO
	moving = false
	@warning_ignore("integer_division")
	position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	print(name, " Has Stopped All Movement.")

#function that sets mode of character
func set_mode(new_mode: Mode):
	if current_mode != new_mode:
		current_mode = new_mode
		mode = new_mode
		print(name, "mode switched to:", new_mode)
		update_look(new_mode)

#This function changes the characters look according to certain modes.
func update_look(new_mode: Mode) -> void:
	match new_mode:
		Mode.NORM:
			norm.visible = true
		Mode.EAT:
			norm.visible = false

#----------------------MOVEMENT CODE--------------------------------------------
#Movement Of Character
func _physics_process(_delta):
	
	handle_input()
	if moving: 
		#move towards target tile
		position = position.move_toward(target_pos, speed * GRID_SIZE * _delta)
		
		
		#stop moving when reach target tile
		if position.distance_to(target_pos) < 0.1:
			position = target_pos
			moving = false
			
			
			#Check if we can change direction while moving
			if next_direction != Vector2.ZERO:
				var dist = position.distance_to(target_pos)
				if dist <= TURN_EARLY_DISTANCE and can_move(next_direction):
					start_move(next_direction)
					return
			elif can_move(direction):
				start_move(direction)
	else: 
		#If not moving, try next direction if possible
		if next_direction != Vector2.ZERO and can_move(next_direction):
			start_move(next_direction)
	

#How The Player Moves Grinbit
func handle_input():
	if Input.is_action_just_pressed("ui_up"):
		next_direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down"):
		next_direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left"):
		next_direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right"):
		next_direction = Vector2.RIGHT



func start_move(dir: Vector2):
	direction = dir
	_last_direction = direction
	@warning_ignore("integer_division")
	target_pos = (position + direction * GRID_SIZE)
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


#Functions for when the Game manager sets to CHASE mode this is what this charcter does 
func on_enter_run_mode():
	#Called when chase mode starts
	set_mode(Mode.EAT)
	speed = 5

func on_exit_run_mode():
	#Called when chase mode ends
	set_mode(default_mode)
	speed = 4.5

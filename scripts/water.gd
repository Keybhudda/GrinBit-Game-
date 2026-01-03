extends CharacterBody2D
#----------------------Scene and Other Node Connections ------------------------
@onready var game_manager: Node2D = %GameManager
@onready var game_state: Node2D = %GameState
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var area_2d: Area2D = $Area2D
@onready var mind_timer: Timer = $MindTimer
@onready var deathscreen: Node2D = %deathscreen
@onready var norm: Sprite2D = $Norm
@onready var run: Sprite2D = $RUN

@export var map: TileMapLayer
#----------------------Based Variables & Modes----------------------------------
@export var default_mode: Mode = Mode.BASE
enum Mode { BASE, CHASE, SHUFFLE, RUN, DEAD }
#Default,mode can change depending on character personality.
var mode: Mode = Mode.BASE


var current_mode: Mode = Mode.BASE

#Finding (GrinBit)
@export_node_path("CharacterBody2D") var player_path : NodePath
#The Speed A Which This Character Chases (GrinBit)
var player: CharacterBody2D = null
var speed := 4
const GRID_SIZE = 16

var direction = Vector2.ZERO
var moving := false
var target_pos = Vector2.ZERO


var decision_timer := 0.0
var decision_interval := 0.5

var path: Array[Vector2] = []
var path_index := 0

signal player_caught

signal Start_Position(entity_name: String, position: Vector2)

var start_pos: Vector2

var has_printed_mode_killable := false

#----------------------Start Code ----------------------------------------------
#Finds Where Grinbit is to track
func _ready():
	# Get the player node from the exported path
	player = get_node(player_path)
	@warning_ignore("integer_division")
	position = map.map_to_local(map.local_to_map(position)).snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	@warning_ignore("integer_division")
	if position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2)):
		start_pos = position
		emit_signal("Start_Position", name, start_pos)
	map.setup_astar_grid()
	set_mode(default_mode)
#This function when called resets the character to a state usually its BASE State
func reset_state():
	#Reset All values and mode back to norm
	norm.visible = true
	run.visible = true
	if get_node("Area2D/C_Body").disabled == true:
		get_node("Area2D/C_Body").disabled = false
	has_printed_mode_DEAD = false
	has_printed_mode_killable = false
	path.clear()
	path_index = 0
	moving = false
	direction = Vector2.ZERO
	target_pos = position
	velocity = Vector2.ZERO
	decision_timer = decision_interval
	set_mode(default_mode)
	print(name, " has been reset.")
#This function changes the characters look according to certain modes.
func update_look(new_mode: Mode) -> void:
	#changes the look of the enemy charcter for when in a certain mode.
	match new_mode:
		default_mode:
			norm.visible = true
		Mode.SHUFFLE:
			norm.visible = true
		Mode.RUN:
			norm.visible = false
		Mode.DEAD:
			norm.visible = false
			run.visible = false
	

#----------------------MOVEMENT CODE--------------------------------------------
var last_behavior: Mode = Mode.CHASE#Variable To Store For Mode Swapping
#Movement Of Character
func _physics_process(_delta: float) -> void:
	decision_timer -= _delta
	
	if player == null or mode == Mode.SHUFFLE:
		set_mode(Mode.SHUFFLE)
	
	
	if decision_timer <= 0.0:
		decision_timer = decision_interval
		if mode == Mode.CHASE and player:
			path = map.get_astar_path(position, player.position)
			path_index = 0
	match mode:
		Mode.BASE:
			character_mind()
		Mode.CHASE:
			chase_player(_delta)
	#---SHUFFLE MODE---
		Mode.SHUFFLE:
			wander_around(_delta)
	#---Kill Mode---
		Mode.RUN:
			killable(_delta)
		Mode.DEAD:
			_dead(_delta)


#This Function if a timer timeout which just tells the character what to do when the timer's time runs out.
func _on_mind_timer_timeout() -> void:
	print(name, " is done thinking!")
	print(name, " current_mode: ", current_mode)
	if mode == Mode.RUN or mode == Mode.DEAD:
		return
	else:
		set_mode(Mode.BASE)
#This is this characters mindset
func character_mind() -> void:
	#this timer is for a change of character movement where the character changes their mode.
	mind_timer.start(10.0)
	print(name, " starts to think. . .")
	
	if last_behavior == Mode.CHASE:
		set_mode(Mode.SHUFFLE)
		last_behavior = Mode.SHUFFLE
		
	else:
		set_mode(Mode.CHASE)
		last_behavior = Mode.CHASE
#This Function Makes the character Chase the player.
func chase_player(_delta: float) -> void:
	if path.is_empty():
		path = map.get_astar_path(position, player.position)
		path_index = 0
		return
		
	if path_index >= path.size():
		path.clear()
		return
		
	target_pos = path[path_index]
		
	position = position.move_toward(target_pos, speed * _delta * GRID_SIZE)
		
	if position.distance_to(target_pos) < 0.5:
		path_index += 1
#This Function makes the charcter wander the map.
func wander_around(_delta: float) -> void:
	var random_cell = map.walkable_cells.pick_random()
	var random_target = map.map_to_local(random_cell)
	
	if path.is_empty():
		path = map.get_astar_path(position, random_target)
		path_index = 0
		return
		
	if path_index >= path.size():
		path.clear()
		return
	
	target_pos = path[path_index]
	
	position = position.move_toward(target_pos, speed * _delta * GRID_SIZE)
	
	if position.distance_to(target_pos) < 0.5:
		path_index += 1

#This Functions Makes this character Killable How They Should While In This State
func killable(_delta: float) -> void:
	if not has_printed_mode_killable:
		print(name, " is Killable!")
		has_printed_mode_killable = true
	var start_position = start_pos
	if path.is_empty():
		@warning_ignore("integer_division")
		path = map.get_astar_path(position, start_position)
		path_index = 0
		return
		
	if path_index >= path.size():
		path.clear()
		return
		
	target_pos = path[path_index]
	position = position.move_toward(target_pos, speed * _delta * GRID_SIZE)
		
	if position.distance_to(target_pos) < 0.5:
		path_index += 1


#Function for when the charcter is cauptured by the player while in RUN Mode
var  has_printed_mode_DEAD := false
func _dead(_delta: float) -> void:
	var start_position = start_pos
	visible = true
	get_node("Area2D/C_Body").disabled = true
	get_node("ZT").disabled = true
	if not has_printed_mode_DEAD:
		print(name, " is DEAD!")
		has_printed_mode_DEAD = true
	
	if path.is_empty():
		@warning_ignore("integer_division")
		path = map.get_astar_path(position, start_position)
		path_index = 0
		return
		
	if path_index >= path.size():
		path.clear()
		return
		
	target_pos = path[path_index]
	position = position.move_toward(target_pos, speed * _delta * GRID_SIZE)
		
	if position.distance_to(target_pos) < 0.5:
		path_index += 1
#function that sets mode of character
func set_mode(new_mode: Mode):
	if current_mode != new_mode:
		current_mode = new_mode
		mode = new_mode
		print(name, "mode switched to:", new_mode)
		update_look(new_mode)

#Standby function
func can_move(dir: Vector2) -> bool:
	@warning_ignore("integer_division")
	var test_pos = (position + dir * GRID_SIZE).snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = test_pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	
	var result = space_state.intersect_point(params)
	for r in result:
		if r.collider.is_in_group("Player"):
			continue
		return false
	return true
#Standby function
func can_move_to(dir: Vector2) -> bool:
	@warning_ignore("integer_division")
	var test_pos = (position + dir * GRID_SIZE).snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = test_pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result = space_state.intersect_point(params)
	for r in result:
		if r.collider.is_in_group("Player"):
			continue
		return false
	return true

#----------------------Combat Code----------------------------------------------
#When this character is caught while in RUN mode.
func _caught():
	print(name, " was caught!")
	path.clear()
	
#Code For When This Character Comes In Contact With The PLayer(GrinBit) and or Other enemy characters
func _on_area_2d_body_entered(body: Node2D) -> void:
	#If player enters area = death scene and or If player eneters area and mode == RUN then add points and eventually enemy back to stary pos
	if body.is_in_group("Player"):
		if mode == Mode.RUN:
			game_manager.add_pointC()
			_caught()
			set_mode(Mode.DEAD)
			animation_player.play("Death")
			return
		else:
			emit_signal("player_caught")
	else:
		if body.is_in_group("Element"):
			print(name, " has crossed paths with ", body.name)
	#Later Feature If body = enemy -> Fight 

#Functions for when the Game manager sets to CHASE mode this is what this charcter does 
func on_enter_run_mode():
	#Called when chase mode starts
	set_mode(Mode.RUN)
	speed = 2

func on_exit_run_mode():
	#Called when chase mode ends
	set_mode(default_mode)
	speed = 4
	reset_state()


#--------------------------------Character Personality = Aggressive But Absent Minded --------------------------------

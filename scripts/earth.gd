extends CharacterBody2D
#----------------------Scene and Other Node Connections ------------------------
@onready var game_state: Node2D = %GameState
@onready var game_manager: Node2D = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var fight_timer: Timer = $FightTimer
@onready var recover_timer: Timer = $RecoverTimer
@onready var area_2d: Area2D = $Area2D
@onready var mind_timer: Timer = $MindTimer
@onready var deathscreen: Node2D = %deathscreen


@onready var fight_cloud: AnimatedSprite2D = $FightCloud
@onready var norm: Sprite2D = $Norm
@onready var run: Sprite2D = $RUN
@onready var dead: Sprite2D = $Dead
@onready var alert: Label = $Alert


@export var map: TileMapLayer
#----------------------Based Variables & Modes----------------------------------
@export var default_mode: Mode = Mode.SHUFFLE
enum Mode { BASE, CHASE, SHUFFLE, RUN, FIGHT, DEAD }
#Default,mode can change depending on character personality.


var current_mode: Mode = Mode.SHUFFLE

#Finding (GrinBit)
@export_node_path("CharacterBody2D") var player_path : NodePath
#The Speed A Which This Character Chases (GrinBit)
var player: CharacterBody2D = null
var speed := 2
const GRID_SIZE = 16


var direction = Vector2.ZERO
var moving = false
var target_pos = Vector2.ZERO

var last_direction = Vector2.ZERO

var decision_timer := 0.0
var decision_interval := 0.7

var path: Array[Vector2] = []
var path_index := 0

signal player_caught

signal Start_Position(entity_name: String, position: Vector2)

var start_pos: Vector2

var has_printed_mode_killable := false

signal element_clash(self_enemy, other_enemy)

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
	norm.visible = true
	run.visible = true
	dead.visible = false
	if get_node("Area2D/C_Body").disabled == true or get_node("ZT").disabled == true:
		enable_collision()
	has_printed_mode_DEAD = false
	has_printed_mode_killable = false
	path.clear()
	path_index = 0
	speed = 2
	moving = false
	direction = Vector2.ZERO
	target_pos = position
	velocity = Vector2.ZERO
	decision_timer = decision_interval
	clashed = false
	recovering = false
	fighting = false
	alert.visible = false
	set_mode(default_mode)
	print(name, " has been reset.")
#This function changes the characters look according to certain modes.
func update_look(new_mode: Mode) -> void:
	match new_mode:
		default_mode:
			norm.visible = true
			dead.visible = false
			fight_cloud.visible = false
		Mode.SHUFFLE:
			norm.visible = true
			dead.visible = true
			fight_cloud.visible = false
		Mode.RUN:
			norm.visible = false
			run.visible = true
			dead.visible = false
			fight_cloud.visible = false
		Mode.DEAD:
			dead.visible = true
			norm.visible = false
			run.visible = false
			fight_cloud.visible = false
		Mode.FIGHT:
			dead.visible = true
			norm.visible = true
			run.visible = false
			fight_cloud.visible = true
#----------------------MOVEMENT CODE--------------------------------------------
#Movement Of Character
func _physics_process(_delta: float) -> void:
	
	decision_timer -= _delta
	
	if player == null:
		print(name, "couldn't find player")
		set_mode(Mode.SHUFFLE)
		
	
	if decision_timer <= 0.0:
		decision_timer = decision_interval
		if current_mode == Mode.CHASE and player:
			path = map.get_astar_path(position, player.position)
			path_index = 0
	match current_mode:
		Mode.BASE:
			character_mind()
		Mode.CHASE:
			chase_player(_delta)
		Mode.SHUFFLE:
			wander_around(_delta)
		#---Kill Mode---
		Mode.RUN:
			killable(_delta)
		Mode.DEAD:
			_dead(_delta)
		Mode.FIGHT:
			fight(_delta)
#Territory area function
func _on_t_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
		
	if current_mode == Mode.RUN or current_mode == Mode.DEAD or current_mode == Mode.FIGHT:
		return
	else:
		if body.is_in_group("Player"):
			alert.visible = false
			print("Player left Grumbl's terrirtory!")
			speed = 2
			set_mode(Mode.BASE)
#Territory area function
func _on_t_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
		
	if current_mode == Mode.RUN or current_mode == Mode.DEAD or current_mode == Mode.FIGHT:
		return
	else:
		if body.is_in_group("Player"):
			alert.visible = true
			print("Player entered Grumbl's terrirtory!")
			speed = 3
			set_mode(Mode.CHASE)
#This is this characters mindset
func character_mind() -> void:
	if current_mode == Mode.FIGHT:
		return
	else:
		set_mode(Mode.SHUFFLE)
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
	
	@warning_ignore("integer_division")
	position = position.move_toward(target_pos, speed * _delta * GRID_SIZE)
	
	if position.distance_to(target_pos) < 0.5:
		path_index += 1
#This Function makes the charcter wander the map.
func wander_around(_delta: float) -> void:
	alert.visible = false
	if recovering == true:
		norm.visible = false
		speed = 2
		call_deferred("disable_collision")
	
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
	
	alert.visible = false
	if current_mode == Mode.RUN and (recovering == true or clashed == true):
		call_deferred("enable_collision")
		
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
	alert.visible = false
#checks if conditions are met then sets character to shuffle for a bit and sets a timer to prevent auto player chase.
	if game_manager.game_mode != game_manager.ModeOfGame.CHASE and (recovering == true and position == start_pos):
		set_mode(Mode.SHUFFLE)
		recover_timer.start(3)
		return
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
		


var fighting := false
func fight(_delta: float) -> void:
	alert.visible = false
	path.clear()
	@warning_ignore("integer_division")
	position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	call_deferred("disable_collision")
	
	if current_mode == Mode.RUN:
		set_mode(Mode.RUN)
		call_deferred("enable_collision")
		return
	else:
		if recovering == true:
			set_mode(Mode.DEAD)

#function that sets mode of character
func set_mode(new_mode: Mode):
	if current_mode != new_mode:
		
		current_mode = new_mode
		print(name, "mode switched to:", new_mode)
		update_look(new_mode)
		
	match new_mode:
		Mode.RUN, Mode.CHASE, Mode.SHUFFLE:
			call_deferred("enable_collision")
		Mode.FIGHT, Mode.DEAD:
			call_deferred("disable_collision")
#Standby function
func can_move(dir: Vector2) -> bool:
	@warning_ignore("integer_division")
	var test_pos = (position + dir * GRID_SIZE)
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
	var test_pos = (position + dir * GRID_SIZE)
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
	

var clashed := false
var recovering := false
#Code For When This Character Comes In Contact With The PLayer(GrinBit) and or Other enemy characters
func _on_area_2d_body_entered(body: Node2D) -> void:
	#If player enters area = death scene and or If player eneters area and mode == RUN then add points and eventually enemy back to stary pos
	if body.is_in_group("Player"):
		if current_mode == Mode.RUN:
			game_manager.add_pointC()
			_caught()
			set_mode(Mode.DEAD)
			animation_player.play("Death")
			return
		else:
			emit_signal("player_caught")
	if body.is_in_group("Element"):
		var opponent := body
		clashed = true
		emit_signal("element_clash", self, opponent)
	#Later Feature If body = enemy -> Fight 

#Functions for when the Game manager sets to CHASE mode this is what this charcter does 
func on_enter_run_mode():
	#Called when chase mode starts
	if not current_mode == Mode.RUN:
		set_mode(Mode.RUN)
		speed = 2

func on_exit_run_mode():
	#Called when chase mode ends
	speed = 2
	reset_state()

func on_enter_fight_mode():
	if current_mode == Mode.RUN:
		call_deferred("enable_collision")
		return
	fighting = true
	clashed = true
	path.clear()
	if fight_timer.is_stopped():
		fight_timer.start(5)
		set_mode(Mode.FIGHT)
		call_deferred("disable_collision")

func _on_fight_timer_timeout() -> void:
	if current_mode == Mode.RUN:
		call_deferred("enable_collision")
		return
	print(name, " Is Done Fighting.")
	on_exit_fight_mode()

func on_exit_fight_mode():
	fighting = false
	clashed = false
	recovering = true
	if current_mode == Mode.RUN:
		set_mode(Mode.RUN)
		call_deferred("enable_collision")
		return
	set_mode(Mode.DEAD)


func on_exit_recovery_mode():
	if current_mode == Mode.RUN:
		call_deferred("enable_collision")
		return
	else :
		if recovering == true and position == start_pos:
			enable_collision()
			reset_state()

func disable_collision():
	get_node("ZT").disabled = true
	get_node("Area2D/C_Body").disabled = true

func enable_collision():
	get_node("ZT").disabled = false
	get_node("Area2D/C_Body").disabled = false

func _on_recover_timer_timeout() -> void:
	if recovering == true:
		print(name, " Has Recovered")
	if current_mode == Mode.RUN:
		call_deferred("enable_collision")
		return
	else :
		reset_state()

#---------------------------Character Personality = Territorial ------------------------------------

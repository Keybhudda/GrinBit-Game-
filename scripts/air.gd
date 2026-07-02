extends CharacterBody2D
#----------------------Scene and Other Node Connections ------------------------
@onready var game_state: Node2D = %GameState
@onready var game_manager: Node2D = %GameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bump: AudioStreamPlayer2D = $Bump

@onready var recover_timer: Timer = $RecoverTimer
@onready var area_2d: Area2D = $Area2D
@onready var mind_timer: Timer = $MindTimer
@onready var deathscreen: Node2D = %deathscreen
@onready var fight_timer: Timer = $FightTimer
@onready var recent_fight_timer: Timer = $RecentFightTimer
@onready var parry_timer: Timer = $ParryTimer
@onready var pop_up_timer: Timer = $PopUpTimer
@onready var delay_timer: Timer = $DelayTimer


@onready var enemies = get_tree().get_nodes_in_group("Element")


@onready var fight_cloud: AnimatedSprite2D = $FightCloud
@onready var norm: Sprite2D = $Norm
@onready var run: Sprite2D = $RUN
@onready var dead: Sprite2D = $Dead
@onready var parry: Sprite2D = $Parry
@onready var scared: Label = $Scared


@export var map: TileMapLayer
#----------------------Based Variables & Modes----------------------------------
@export var default_mode: Mode = Mode.BASE
enum Mode { BASE, CHASE, SHUFFLE, RUN, FIGHT, DEAD }
#Default,mode can change depending on character personality.


var current_mode: Mode = Mode.BASE

#Finding (GrinBit)
@export_node_path("CharacterBody2D") var player_path : NodePath
#The Speed A Which This Character Chases (GrinBit)
var player: CharacterBody2D = null
var speed := 4
const GRID_SIZE = 16


var direction = Vector2.ZERO
var moving = false
var target_pos = Vector2.ZERO


var decision_timer := 0.0
var decision_interval := 0.5

var path: Array[Vector2] = []
var path_index := 0

signal player_caught

signal Start_Position(entity_name: String, position: Vector2)

var start_pos: Vector2

var has_printed_mode_killable := false

var recently_fought := false

signal element_fight

signal mode_change


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
	update_look(current_mode)
	if get_node("Area2D/C_Body").disabled == true or get_node("ZT").disabled == true:
		enable_collision()
	has_printed_mode_DEAD = false
	has_printed_mode_killable = false
	path.clear()
	path_index = 0
	speed = 4
	moving = false
	direction = Vector2.ZERO
	target_pos = position
	velocity = Vector2.ZERO
	decision_timer = decision_interval
	recovering = false
	fighting = false
	has_parried = false
	if game_manager.current_state == game_manager.StateOfGame.RESETTING:
		recently_fought = false
	stop_all_timers()
	set_mode(default_mode)
	print(name, " has been reset.")
#This function changes the characters look according to certain modes.
func update_look(new_mode: Mode) -> void:
	dead.visible = false
	norm.visible = false
	run.visible = false
	parry.visible = false
	fight_cloud.visible = false
	
	match new_mode:
		Mode.BASE:
			norm.visible = true
			dead.visible = true
		Mode.CHASE:
			norm.visible = true
			dead.visible = true
		Mode.SHUFFLE:
			norm.visible = true
			dead.visible = true
		Mode.RUN:
			run.visible = true
		Mode.DEAD:
			dead.visible = true
		Mode.FIGHT:
			norm.visible = true
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
			intercept_player(_delta)
		Mode.SHUFFLE:
			wander_around(_delta)
		#---Kill Mode---
		Mode.RUN:
			killable(_delta)
		Mode.DEAD:
			_dead(_delta)
		Mode.FIGHT:
			fight(_delta)

#This Function if a timer timeout which just tells the character what to do when the timer's time runs out.
func _on_mind_timer_timeout() -> void:
	print(name, " has Came to Mind!")
	if current_mode in [Mode.FIGHT, Mode.DEAD, Mode.RUN]:
		return
	else:
		set_mode(Mode.BASE)

#This is this characters mindset
func character_mind() -> void:
	if not can_think():
		return
	print(name, " is thinking. . .")
	# 50/50 of either going into Chase mode or Shuffle.
	if randi() % 2 == 0:
		set_mode(Mode.SHUFFLE)
		mind_timer.start(8.0)
		print(name, " is Scared and is wandering")
	else:
		set_mode(Mode.CHASE)
		mind_timer.start(8.0)
		print(name, "is trying to cut off Player!")


#This Function is a unique function only for this character when They try to cut the player off. 
var intercept_distance := GRID_SIZE * 4 # x grid cells ahead
func intercept_player(_delta: float) -> void:
	if player == null:
		print(name, " cant find player!")
		return
	
	
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



#Old Tries of making cut off code work better
func get_intercept_tile(tiles_ahead: int ) -> Vector2:
	var place = player._last_direction
	if place == Vector2.ZERO:
		print("the player's position", player.position)
		return player.position
	
	var tile_dir := Vector2i(place)
	
	var player_tile: Vector2i = map.local_to_map(player.position)
	
	var intercept_tile: Vector2i = player_tile + tile_dir * tiles_ahead
	
	if not map.astar_grid.is_in_boundsv(intercept_tile):
		intercept_tile = player_tile
	print (name, "is targeting", intercept_tile)
	return map.map_to_local(intercept_tile)

func to_vector2_array(arr: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for p in arr:
		result.append(p)
	return result


#This Function Makes the character Chase the player. - This character doesn't use this
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

	if current_mode == Mode.FIGHT:
		set_mode(Mode.FIGHT)

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

#FightMode Functions Where Two Elements/enemies stop movement and fight eachother
var fighting := false
func fight(_delta: float) -> void:
	if game_manager.current_state == game_manager.StateOfGame.DEAD:
		return
	path.clear()
	@warning_ignore("integer_division")
	position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	fight_cloud.visible = true
	call_deferred("disable_collision")
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		call_deferred("enable_collision")
		return
	else:
		if recovering == true:
			set_mode(Mode.DEAD)

#first attempt at making mode transitioning delay.
var mode_transition_timer := 0.0
@export var mode_transition_delay := 0.15
var freeze_path_recalc := false
var nextmode = Mode.BASE
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

#not used function idea for this is to help with enemy mode transitioning. so when they switch modes is much smoother.
func switchmode(new_mode: Mode):
	emit_signal("mode_change", new_mode)

	
func _on_delay_timer_timeout() -> void:
	set_mode(nextmode)
	print("Next Mode Activated!")

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
	if pop_spawned:
		display_points()
	
	if pop_spawned == false:
		spawn_score_popup()
	path.clear()


var recovering := false
var elements_can_fight := false
var pop_spawned := false
#Code For When This Character Comes In Contact With The PLayer(GrinBit) and or Other enemy characters
func _on_area_2d_body_entered(body: Node2D) -> void:
	#If player enters area = death scene and or If player eneters area and mode == RUN then add points and eventually enemy back to stary pos
	if body.is_in_group("Player"):
		if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
			_caught()
			set_mode(Mode.DEAD)
			animation_player.play("Death")
			return
		else:
			emit_signal("player_caught")
	if body.is_in_group("Element"):
		if game_manager.current_state == game_manager.StateOfGame.DEAD:
			return
		var opponent := body
		if recently_fought or opponent.recently_fought:
			cant_fight()
			opponent.cant_fight()
			print("Elements cannot fight.")
			return
		opponent.start_fight()
		on_enter_fight_mode()
		emit_signal("element_fight")
		print(name, " is fighting ", opponent.name)

#For Visual Pop for when enemy is collected
var popup = preload("res://scenes/Menus & Pop Ups/UI-Assets/Score_popup.tscn").instantiate()
func spawn_score_popup():
	var points = game_manager.combo_points()
	get_tree().current_scene.add_child(popup)
	popup.visible = true
	@warning_ignore("integer_division")
	popup.position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	popup.set_score(points)
	pop_spawned = true
	pop_up_timer.start(2)

func display_points():
	var points = game_manager.combo_points()
	popup.visible = true
	@warning_ignore("integer_division")
	popup.position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	popup.set_score(points)
	pop_up_timer.start(2)

func _on_pop_up_timer_timeout() -> void:
	if popup:
		popup.visible = false

var has_parried := false
func cant_fight():
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		return
	if not has_parried:
		bump.play()
		has_parried = true
		parry_timer.start(2)
	if has_parried:
		parry.visible = true
		dead.visible = false
		norm.visible = false
		run.visible = false
		fight_cloud.visible = false

func _on_parry_timer_timeout() -> void:
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		bump.stop()
		return
	if has_parried:
		has_parried = false
		update_look(current_mode)

#--------- Helper Functions --------------#
func start_fight():
	if game_manager.current_state == game_manager.StateOfGame.DEAD:
		return
	print("Someone Is Fighting ", name)
	on_enter_fight_mode()

func can_think() -> bool:
	if current_mode in [Mode.FIGHT, Mode.DEAD]:
		return false
		
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		return false
		
	return true

func stop_all_timers():
	mind_timer.stop()
	recover_timer.stop()
	fight_timer.stop()

#Functions for when the Game manager sets to CHASE mode this is what this charcter does 
func on_enter_run_mode():
	stop_all_timers()
	recently_fought = false
	recent_fight_timer.stop()
	set_mode(Mode.RUN)
	speed = 3

func on_exit_run_mode():
	#Called when chase mode ends
	speed = 4
	reset_state()

#Functions for when character is fighting another element
func on_enter_fight_mode():
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		call_deferred("enable_collision")
		return
	if game_manager.current_state == game_manager.StateOfGame.DEAD:
		return
	
	fighting = true
	mind_timer.stop()
	path.clear()
	if fight_timer.is_stopped():
		fight_timer.start(5)
		set_mode(Mode.FIGHT)
		call_deferred("disable_collision")
#FightTimer Function
func _on_fight_timer_timeout() -> void:
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		call_deferred("enable_collision")
		return
	print(name, " Is Done Fighting.")
	on_exit_fight_mode()

func _on_recent_fight_timer_timeout() -> void:
	print(name, " can fight again!")
	recently_fought = false

#set character into a dead state
func on_exit_fight_mode():
	fighting = false
	recovering = true
	recently_fought = true
	recent_fight_timer.start(20)
	print("recent fight Time Started!")
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		call_deferred("enable_collision")
		return
	else:
		set_mode(Mode.DEAD)
#RecoverTimer Function
func _on_recover_timer_timeout() -> void:
	print(name, " Has Recovered")
	recovering = false
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		call_deferred("enable_collision")
		return
	else :
		on_exit_recovery_mode()

#reset character back to norm
func on_exit_recovery_mode():
	if game_manager.game_mode == game_manager.ModeOfGame.CHASE:
		call_deferred("enable_collision")
		return
	else :
		if recovering == false:
			enable_collision()
			reset_state()

#Functions for toggling collision
func disable_collision():
	get_node("ZT").disabled = true
	get_node("Area2D/C_Body").disabled = true

func enable_collision():
	get_node("ZT").disabled = false
	get_node("Area2D/C_Body").disabled = false


#----------------------------Character Personality = Skittish but Aggressive------------------------

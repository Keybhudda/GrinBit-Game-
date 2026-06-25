extends Node
#This Is used to Manage & keep track of game progress Basically Controls The Game. 

#-----------------------Modes---------------------------------------------------
enum StateOfGame {RUNNING, DEAD, RESETTING, READY }
enum ModeOfGame {NORM, CHASE}

var current_state: StateOfGame = StateOfGame.RUNNING
var game_mode: ModeOfGame = ModeOfGame.NORM

#-----------------------Node Connections----------------------------------------
@onready var game_state: Node2D = %GameState

@onready var score_label: Label = $score_label
@onready var _1_lives: Sprite2D = $"1Lives"
@onready var _2_lives: Sprite2D = $"2Lives"
@onready var _3_lives: Sprite2D = $"3Lives"


@onready var deathscreen: Node2D = get_tree().get_first_node_in_group("deathscreen")
@onready var player_lives = get_node("/root/Player_Lives")
@export var map: TileMapLayer
#-----------------------Music and Sounds----------------------------------------
@onready var player_death: AudioStreamPlayer2D = $PlayerDeath
@onready var backgroundmusic: AudioStreamPlayer2D = $Backgroundmusic
@onready var fighting: AudioStreamPlayer2D = $Fighting

#-----------------------Timers--------------------------------------------------
@onready var death_timer: Timer = get_tree().get_first_node_in_group("DeathTimer")
@onready var ready_timer: Timer = get_tree().get_first_node_in_group("ReadyTimer")
@onready var chase_timer: Timer = get_tree().get_first_node_in_group("ChaseTimer")
@onready var switch_timer: Timer = get_tree().get_first_node_in_group("SwitchTimer")
@onready var go_timer: Timer = get_tree().get_first_node_in_group("GoTimer")
@onready var reset_timer: Timer = get_tree().get_first_node_in_group("ResetTimer")


#-----------------------Characters Ref------------------------------------------
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var enemies = get_tree().get_nodes_in_group("Element")
@onready var tokens = get_tree().get_nodes_in_group("Token")
@onready var Ktokens = get_tree().get_nodes_in_group("K-Tokens")

#-----------------------Base Variables------------------------------------------
var player_start_position: Vector2
var enemy_start_position = {}
var GRID_SIZE = 16
var run_combo := 0

var game_reset := false
#----------------------------Start Code-----------------------------------------
func _ready() -> void:
	_update_score_label()
	begin_game()
	update_lives()
	game_mode = ModeOfGame.NORM
	print("GameManager instance:", self.get_path())
	game_state.debug_print_items()
	
	if player:
		print("Connecting Player:", player.name)
		player.connect("Start_Position", Callable(self, "_on_Start_Position"))
	
	for enemy in enemies:
		print("Connecting enemy:", enemy.name)
		enemy.connect("player_caught", Callable(self, "_on_player_caught"))
		enemy.connect("Start_Position", Callable(self, "_on_Start_Position"))
		enemy.connect("element_fight", Callable(self, "_on_element_fight"))
	
	for toke in tokens:
		print("Connecting tokens")
		toke.connect("token_deactivated", Callable(self, "_on_token_deactivation"))
	
	for ktoke in Ktokens:
		print("Connecting tokens")
		ktoke.connect("token_deactivated", Callable(self, "_on_token_deactivation"))
	
	game_state.connect("all_items_collected", Callable(self, "_on_level_complete"))
	
	current_state = StateOfGame.RUNNING
	
 
#function supposed to help with enemy mode transition *not being used as of now*
func _on_mode_change(new_mode):
	for enemy in enemies:
		enemy.nextmode = new_mode
		enemy.delay_timer.start(.5)

func _on_element_fight():
	if game_mode == ModeOfGame.CHASE:
		fighting.stop()
		return
	#Line Below Should Keep Enemies From fighting after player death and level reset. 
	if current_state == StateOfGame.DEAD or StateOfGame.RESETTING:
		fighting.stop()
	fighting.play()

func _on_token_deactivation():
	set_game_reset()
	print("game_reset: " ,game_reset)
	return


#No longer should be used
func _on_element_clash(enemy_a, enemy_b):
	print(enemy_a.name, "Has Clashed With Another Element")
	if game_mode == ModeOfGame.CHASE:
		return
	else :
		for enemy in enemies:
				@warning_ignore("integer_division")
				print(enemy_a.name, " Is Fighting. ", enemy_b.name, " Around ", enemy_a.position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2)), " And ", enemy_b.position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2)))
				enemy_a.on_enter_fight_mode()
				enemy_b.on_enter_fight_mode()
				fighting.play()

func update_lives():
	if Player_Lives.Player_Lives == 4:
		_3_lives.visible = true
		_2_lives.visible = false
		_1_lives.visible = false
		
	if Player_Lives.Player_Lives == 3:
		_3_lives.visible = false
		_2_lives.visible = true
		_1_lives.visible = false
	if Player_Lives.Player_Lives == 2: 
		_3_lives.visible = false
		_2_lives.visible = false
		_1_lives.visible = true
	if Player_Lives.Player_Lives == 1: 
		_3_lives.visible = false
		_2_lives.visible = false
		_1_lives.visible = false


#A timer to give time to play game beat music and then send to game over screen for now until we make more levels
func _on_switch_timer_timeout() -> void:
	get_tree().paused = false
	#HERES What Causes THat Fade When Moving to the next level
	call_deferred("go_next_level")
#where when a level is complete it send you to the next level. 
func _on_level_complete():
	get_tree().paused = true
	print("Level Complete!")
	deathscreen.visible = true
	deathscreen.level_complete()
	switch_timer.start(2)




#Sends Player to level Until all levels are comepleted then 
func go_next_level():
	GlobalData.levels[GlobalData.current_level_index]["completed"] = true
	GlobalData.current_level_index += 1
	
	if GlobalData.current_level_index > 1 and GlobalData.current_level_index % 2 == 0:
		Player_Lives.add_life()
	
	if GlobalData.current_level_index < GlobalData.levels.size():
		get_tree().change_scene_to_file("res://scenes/Level_%d.tscn" %
	(GlobalData.current_level_index + 1))
		
	
	if GlobalData.current_level_index >= GlobalData.levels.size():
		game_won()
		return
	print(GlobalData.current_level_index)

#normal way of switching levels -OlD Tho want to use whats above
func game_won():
	get_tree().change_scene_to_file("res://scenes/Menus & Pop Ups/game_won_screen.tscn")
#Gets the starting points for all characters to use later for reload.
func _on_Start_Position(entity_name: String, position: Vector2):
	if entity_name == "Grinbit":
		player_start_position = position
	else: 
		enemy_start_position[entity_name] = position
	print("Position Set ", entity_name, " at", position)

#Sets Game mode to then set Enemies and player to their according modes 
func set_game_mode(new_mode: ModeOfGame):
	if game_mode == new_mode:
		return
	game_mode = new_mode
	match game_mode:
		ModeOfGame.NORM:
			print("Game Mode -> NORM")
			for enemy in enemies:
				if enemy and enemy.is_inside_tree():
					enemy.on_exit_run_mode()
		
		ModeOfGame.CHASE:
			fighting.stop()
			print("Game Mode -> CHASE")
			for enemy in enemies:
				if enemy and enemy.is_inside_tree():
					enemy.on_enter_run_mode()
			chase_timer.start(8.0)

#Adds Time to Chase Timer If a additional k token is collected while chase mode is still active.
func Check_timer():
	if game_mode == ModeOfGame.CHASE:
		print("extending Chase mode Time")
		chase_timer.stop()
		chase_timer.start(8.0)
	else:
		if game_mode == ModeOfGame.NORM:
			print("Chase mode now activated.")


#Scoring System
func add_point():
	GlobalData.total_score += 25
	
	_update_score_label()
func add_point1():
	GlobalData.total_score += 75



	_update_score_label()
func add_pointf1():
	GlobalData.total_score += 300

	_update_score_label()
func add_pointf2():
	GlobalData.total_score += 400

	_update_score_label()
func add_pointf3():
	GlobalData.total_score += 600

	_update_score_label()
	#This is the new add point function for when the player collides with an enemy earning them points
#Old Point amount/system for enemies
func add_pointC():
	GlobalData.total_score += 600
	
	_update_score_label()
#New and more accurate Point system
func combo_points():
	run_combo += 1
	
	var points = 200 * (1 << (run_combo - 1))
	GlobalData.total_score += points
	print("Enemy Combo: ", run_combo, " Points: ", points)
	
	if  run_combo == enemies.size():
		GlobalData.total_score += 600
		print("All Elements Defeated! +600!")
	_update_score_label()
	return points
#function That updates score
func _update_score_label():
	score_label.text = "Score: " + str(GlobalData.total_score)
	

func stop_fight_timers():
	for enemy in enemies:
		enemy.fight_timer.stop()
	print("all fights have been stopped.")

#function that is called when a signal is emitted from a player and enemy collision
func _on_player_caught():
	if current_state != StateOfGame.RUNNING:
		return
	print("player caught!")
	
	current_state = StateOfGame.DEAD
	if current_state == StateOfGame.DEAD:
		set_game_reset()
		print("game_reset: " ,game_reset)
		reset_timer.start(5.6)
		print("reset_timer started!")
		get_tree().paused = true
		player_death.play()
		update_lives()
	Player_Lives.lose_life()#Function to subtract lives after each death.
	
	if Player_Lives.Player_Lives > 0:
		deathscreen.visible = true
		deathscreen.death()
		
		death_timer.start(2.0) #Starts Timer to display death 
	else:
		print("GAME OVER! OUT OF LIVES")
		get_tree().paused = false
		call_deferred("out_of_lives")

#Function for when the player runs out of lives
func out_of_lives():
	GlobalData.is_game_over = true
	get_tree().change_scene_to_file("res://scenes/Menus & Pop Ups/gameover.tscn")


#Function For when to init reset of the game. to then continue
func _on_death_timer_timeout() -> void:
	deathscreen.visible = false
	update_lives()
	reset_round()

#reset the scene 
func reset_round():
	print("resetting round. . .")
	current_state = StateOfGame.RESETTING
	
	if current_state == StateOfGame.RESETTING:
		if player:
			player.stop_movement()
			player.global_position = player_start_position
			print("Player reset to:", player_start_position)
	
		stop_fight_timers()
		fighting.stop()
		update_lives()
		for enemy in enemies:
			if enemy.name in enemy_start_position:
				enemy.reset_state()
				enemy.global_position = enemy_start_position[enemy.name]
				print("Enemy ", enemy.name, " reset to:", enemy_start_position[enemy.name])
		
		print("Positions reset!")
		start_game()

func set_game_reset():
	if game_reset:
		game_reset = false
	else: game_reset = true

func _on_reset_timer_timeout() -> void:
	game_reset = false
	print("game_reset: " ,game_reset)
	return



#For anything time the game goes through a stoppage to then continue
func start_game():
	current_state = StateOfGame.READY
	get_tree().paused = true
	deathscreen.visible = true
	deathscreen.restarting()
	ready_timer.start(3.0)
	print("Ready?")

#for start of game 
func begin_game():
	print(GlobalData.levels)
	current_state = StateOfGame.READY
	get_tree().paused = true
	deathscreen.visible = true
	deathscreen.restarting()
	ready_timer.start(3.0)
	print("Ready?")

#Visual reset functions to help player know whats going on
func _on_ready_timer_timeout() -> void:
	deathscreen.start()
	go_timer.start(0.5)

func _on_go_timer_timeout() -> void:
	get_tree().paused = false
	print("Go!")
	deathscreen.visible = false
	current_state = StateOfGame.RUNNING


#Chase Mode Function 
func _on_chase_mode_activated():
	print("CHASE MODE ACTIVATED!")
	fighting.stop()
	player.on_enter_run_mode()
	for enemy in enemies:
		enemy.path.clear()
	set_game_mode(ModeOfGame.CHASE)


func _on_chase_timer_timeout() -> void:
	run_combo = 0
	print("CHASE MODE ENDED!")
	player.on_exit_run_mode()
	set_game_mode(ModeOfGame.NORM)

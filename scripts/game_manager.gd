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


@onready var deathscreen: Node2D = get_tree().get_first_node_in_group("deathscreen")
@onready var player_lives = get_node("/root/Player_Lives")
@export var map: TileMapLayer
#-----------------------Music and Sounds----------------------------------------
@onready var player_death: AudioStreamPlayer2D = $PlayerDeath
@onready var backgroundmusic: AudioStreamPlayer2D = $Backgroundmusic

#-----------------------Timers--------------------------------------------------
@onready var death_timer: Timer = get_tree().get_first_node_in_group("DeathTimer")
@onready var ready_timer: Timer = get_tree().get_first_node_in_group("ReadyTimer")
@onready var chase_timer: Timer = get_tree().get_first_node_in_group("ChaseTimer")
@onready var switch_timer: Timer = get_tree().get_first_node_in_group("SwitchTimer")
@onready var go_timer: Timer = get_tree().get_first_node_in_group("GoTimer")
@onready var fight_timer: Timer = get_tree().get_first_node_in_group("FightTimer")

#-----------------------Characters Ref------------------------------------------
@onready var player = get_tree().get_first_node_in_group("Player")
@onready var enemies = get_tree().get_nodes_in_group("Element")

#-----------------------Base Variables------------------------------------------
var score = 0
var total_score = score
var player_start_position: Vector2
var enemy_start_position = {}
var GRID_SIZE = 16

#----------------------------Start Code-----------------------------------------
func _ready() -> void:
	start_game()
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
		enemy.connect("element_clash", Callable(self, "_on_element_clash"))
	
	game_state.connect("all_items_collected", Callable(self, "_on_level_complete"))
	
	current_state = StateOfGame.RUNNING
	
func _on_element_clash(body, opponent):
	print(body.name, "Has Clashed With Another Element")
	if game_mode == ModeOfGame.CHASE:
		return
	else :
		for enemy in enemies:
			if enemy.clashed == true and opponent.clashed == true:
				@warning_ignore("integer_division")
				print(enemy.name, " Is Fighting. ", opponent.name, " Around ", enemy.position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2)), " And ", opponent.position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2)))
				start_battle_timer(5, enemy, opponent)

func start_battle_timer(duration: float, enemy, opponent) -> void:
	if game_mode == ModeOfGame.CHASE:
		return
	else:
		enemy.on_enter_fight_mode()
		opponent.on_enter_fight_mode()
		var timer:= Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.autostart = true
	
	
		add_child(timer)
	
		timer.timeout.connect(_on_battle_timer_timeout)

func _on_battle_timer_timeout() -> void:
	if game_mode == ModeOfGame.CHASE:
		return
	else:
		for enemy in enemies:
			if enemy.clashed == true:
				print(enemy.name, " Is Done Fighting.")
				enemy.on_exit_fight_mode()

#no longer in use 
func _on_fight_timer_timeout() -> void:
	if game_mode == ModeOfGame.CHASE:
		return
	else:
		for enemy in enemies:
			if enemy.clashed == true:
				enemy.recovering = true
				print(enemy.name, " Is Done Fighting.")
				enemy.on_exit_fight_mode()







#A timer to give time to play game beat music and then send to game over screen for now until we make more levels
func _on_switch_timer_timeout() -> void:
	pass
#where when a level is complete it send you to the next level. 
func _on_level_complete():
	GlobalData.total_score = score
	print("Level Complete!")
	call_deferred("game_won")

#Sends Player to Game won screen for now Will send them to next level later
func game_won():
	get_tree().change_scene_to_file("res://scenes/Menus & Pop Ups/game_won_screen.tscn")
	Player_Lives.reset()
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
	score += 25
	
	_update_score_label()
func add_point1():
	score += 75



	_update_score_label()
func add_pointf1():
	score += 400

	_update_score_label()
func add_pointf2():
	score += 300

	_update_score_label()
func add_pointf3():
	score += 600

	_update_score_label()
	#This is the new add point function for when the player collides with an enemy earning them points
func add_pointC():
	score += 600
	
	_update_score_label()
#function That updates score
func _update_score_label():
	score_label.text = "Score: " + str(score)
	

#function that is called when a signal is emitted from a player and enemy collision
func _on_player_caught():
	if current_state != StateOfGame.RUNNING:
		return
	
	print("player caught!")
	current_state = StateOfGame.DEAD
	if current_state == StateOfGame.DEAD:
		get_tree().paused = true
		player_death.play()
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
	GlobalData.total_score = score
	get_tree().change_scene_to_file("res://scenes/Menus & Pop Ups/gameover.tscn")
	Player_Lives.reset()
#Function For when to init reset of the game. to then continue
func _on_death_timer_timeout() -> void:
	deathscreen.visible = false
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
	
		for enemy in enemies:
			if enemy.name in enemy_start_position:
				enemy.reset_state()
				enemy.global_position = enemy_start_position[enemy.name]
				print("Enemy ", enemy.name, " reset to:", enemy_start_position[enemy.name])
		
		print("Positions reset!")
		start_game()

func start_game():
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
	player.on_enter_run_mode()
	for enemy in enemies:
		enemy.path.clear()
	set_game_mode(ModeOfGame.CHASE)


func _on_chase_timer_timeout() -> void:
	print("CHASE MODE ENDED!")
	player.on_exit_run_mode()
	set_game_mode(ModeOfGame.NORM)

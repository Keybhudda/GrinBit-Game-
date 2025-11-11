extends Node
#This Is used to also keep track of game progress but also to be used to call game functions like the start menu, game over menu, and more. 
#Could Add The Chase Mode Event fuction in here.
# will mostlikely have to make the score save by its self.

enum StateOfGame {RUNNING, DEAD, RESETTING, READY }
enum ModeOfGame {NORM, CHASE}

var current_state: StateOfGame = StateOfGame.RUNNING
var game_mode: ModeOfGame = ModeOfGame.NORM

@onready var game_state: Node2D = %GameState
@onready var score_label: Label = $score_label
@onready var deathscreen: Node2D = get_tree().get_first_node_in_group("deathscreen")
@onready var player_lives = get_node("/root/Player_Lives")
@export var map: TileMapLayer

@onready var death_timer: Timer = get_tree().get_first_node_in_group("DeathTimer")
@onready var ready_timer: Timer = get_tree().get_first_node_in_group("ReadyTimer")
@onready var chase_timer: Timer = get_tree().get_first_node_in_group("ChaseTimer")

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var enemies = get_tree().get_nodes_in_group("Element")


var score = 0
var total_score = score
var player_start_position: Vector2
var enemy_start_position = {}


func _ready() -> void:
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
	
	game_state.connect("all_items_collected", Callable(self, "_on_level_complete"))
	
	current_state = StateOfGame.RUNNING
	
	
func _on_level_complete():
	print("Level Complete!")




func _on_Start_Position(entity_name: String, position: Vector2):
	if entity_name == "Grinbit":
		player_start_position = position
	else: 
		enemy_start_position[entity_name] = position
	print("Position Set ", entity_name, " at", position)


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
			chase_timer.start(10.0)


#Scoring System
func add_point():
	score += 25
	
	_update_score_label()
func add_point1():
	score += 75

	_update_score_label()
func add_pointf1():
	score += 200

	_update_score_label()
func add_pointf2():
	score += 300

	_update_score_label()
func add_pointf3():
	score += 500

	_update_score_label()
	#This is the new add point function for when the player collides with an enemy earning them points
func add_pointC():
	score += 600
	
	_update_score_label()

func _update_score_label():
	score_label.text = "Score: " + str(score)
	


func _on_player_caught():
	if current_state != StateOfGame.RUNNING:
		return
	
	
	print("player caught!")
	current_state = StateOfGame.DEAD
	if current_state == StateOfGame.DEAD:
		get_tree().paused = true
	Player_Lives.lose_life()#Function to subtract lives after each death.
	
	if Player_Lives.Player_Lives > 0:
		deathscreen.visible = true
		deathscreen.death()
		death_timer.start(2.0) #Starts Timer to display death 
	else:
		print("GAME OVER! OUT OF LIVES")
		get_tree().paused = false
		call_deferred("out_of_lives")

func out_of_lives():
	GlobalData.total_score = score
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")
	Player_Lives.reset()

func _on_death_timer_timeout() -> void:
	deathscreen.visible = false
	reset_round()

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
	ready_timer.start(3.0)
	print("Ready?")


func _on_ready_timer_timeout() -> void:
	get_tree().paused = false
	print("Go!")
	current_state = StateOfGame.RUNNING

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

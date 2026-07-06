extends Node
#Keeps Track of Players Score While playing
#Eventually would like to add the ability to save game highscores for each user and maybe even out of everyone whom plays the game. 
var total_score: int = 0
var high_score: int = 0
var is_game_over := false
var current_level_index: int = 0


var levels = [
	{"name": "Level 1", "completed": false},
	{"name": "Level 2", "completed": false},
	{"name": "Level 3", "completed": false},
	{"name": "Level 4", "completed": false},
	{"name": "Level 5", "completed": false},
	{"name": "Level 6", "completed": false},
	{"name": "Level 7", "completed": false},
	{"name": "Level 8", "completed": false},
	{"name": "Level 9", "completed": false},
	{"name": "Level 10", "completed": false}
	
	]

func _ready():
	load_high_score()

func check_new_high_score():
	if total_score > high_score:
		high_score = total_score
		save_high_score()

func save_high_score():
	var file = FileAccess.open("user://save_data.save", FileAccess.WRITE)
	file.store_var(high_score)
	file.close()

func load_high_score():
	if FileAccess.file_exists("user://save_data.save"):
		var file = FileAccess.open("user://save_data.save", FileAccess.READ)
		high_score = file.get_var()
		file.close()
	else:
		high_score = 0

func reset_high_score():
	high_score = 0
	save_high_score()
	

func start_new_game():
	if GlobalData.is_game_over:
		GlobalData.total_score = 0
		Player_Lives.reset()
		current_level_index = 0
		GlobalData.is_game_over = false

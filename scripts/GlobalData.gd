extends Node
#Keeps Track of Players Score While playing
#Eventually would like to add the ability to save game highscores for each user and maybe even out of everyone whom plays the game. 
var total_score: int = 0
var high_score: int = 0


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

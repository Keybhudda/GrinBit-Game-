extends Control
#This is The Game Won Screen Script
@onready var winning_music: AudioStreamPlayer2D = $winning_music

@onready var finalscore: Label = $finalscore
@onready var highscore: Label = $highscore


func _ready() -> void:
	GlobalData.check_new_high_score()
	
	if GlobalData.high_score > 0:
		highscore.text = "High Score: " + str(GlobalData.high_score)
	finalscore.text = "Final Score: " + str(GlobalData.total_score)
	
	winning_music.play()

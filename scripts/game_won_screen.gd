extends Control
#This is The Game Won Screen Script
@onready var winning_music: AudioStreamPlayer2D = $winning_music

@onready var finalscore: Label = $finalscore


func _ready() -> void:
	finalscore.text = "Final Score: " + str(GlobalData.total_score)
	winning_music.play()

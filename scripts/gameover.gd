extends Control
#This Is The Game Over Screen Script
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var endscore: Label = $VBoxContainer/endscore
@onready var highscore: Label = $VBoxContainer/highscore

@onready var startmenu: Button = $VBoxContainer/startmenu
@onready var quitbutton: Button = $VBoxContainer/quitbutton

var input_enalbed = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalData.check_new_high_score()
	
	if GlobalData.high_score > 0:
		highscore.text = "High Score: " + str(GlobalData.high_score)
		
	endscore.text = "Final Score: " + str(GlobalData.total_score)
	
	audio_stream_player_2d.play()
	startmenu.grab_focus()
	
	await get_tree().create_timer(0.2).timeout


func _on_resethighscorebtn_pressed() -> void:
	pass # Replace with function body.

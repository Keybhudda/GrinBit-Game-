extends Control
#This Is The Game Over Screen Script
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var endscore: Label = $VBoxContainer/endscore

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	endscore.text = "Final Score: " + str(GlobalData.total_score)
	audio_stream_player_2d.play()

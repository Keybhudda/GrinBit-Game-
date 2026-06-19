extends Control
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var screen: Node2D = $Screen
@onready var menu_time: Timer = $MenuTime

@onready var startbutton: Button = $VBoxContainer/startbutton
@onready var how_to_btn: Button = $VBoxContainer/how_to_btn
@onready var quitbutton: Button = $VBoxContainer/quitbutton

var input_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen.visible = true
	menu_time.start(2)
	audio_stream_player_2d.play()
	startbutton.grab_focus()
	
	await get_tree().create_timer(0.2).timeout
	input_enabled = true


func _on_menu_time_timeout() -> void:
	FadeScreen.transition()
	await FadeScreen.on_transition_finished
	screen.visible = false

extends Control

@onready var startmenu: Button = $startmenu


var input_enabled = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	startmenu.grab_focus()
	
	await get_tree().create_timer(0.2).timeout
	input_enabled = true

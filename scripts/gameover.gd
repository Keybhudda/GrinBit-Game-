extends Control

@onready var endscore: Label = $VBoxContainer/endscore

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	endscore.text = "Final Score: " + str(GlobalData.total_score)

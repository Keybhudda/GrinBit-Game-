extends Node2D

@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func set_score(points):
	label.text = "+" + str(points)
	

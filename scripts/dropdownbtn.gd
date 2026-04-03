extends Button

@onready var panel: Panel = $"../Panel"

var showing := false



func _on_pressed() -> void:
	panel.visible = true

extends Button



func _on_pressed() -> void:
	GlobalData.reset_high_score()
	print("Highscore reset!")

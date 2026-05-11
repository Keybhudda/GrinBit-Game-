extends Button
#Starts The Game

func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Level_1.tscn")
	GlobalData.start_new_game()

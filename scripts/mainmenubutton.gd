extends Button
#Takes Player Back To Main menu

func _on_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menus & Pop Ups/startmenu.tscn")

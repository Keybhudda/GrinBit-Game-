extends Node2D
#This Script Is Called When The Player Collides With An Enemy.
#----------------------Base Vars----------------------------------------------
@onready var youdied: Label = %youdied

#----------------------Action Code----------------------------------------------
func death():
	%youdied.text = "\nYou Were Caught!\nLives Left " + str(Player_Lives.Player_Lives)

func restarting():
	%youdied.text = "\n Ready?"

func start():
	%youdied.text = "\n Go!"

func level_complete():
	%youdied.text = "\n Level \n Completed!"

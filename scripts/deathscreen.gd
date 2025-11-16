extends Node2D
#This Script Is For The Screen That Pops Up When An Enemy Catches You!
@onready var youdied: Label = $youdied


func death():
	youdied.text = "\nYou Were Caught!\nLives Left " + str(Player_Lives.Player_Lives)

func restarting():
	youdied.text = "\n Ready?"

func start():
	youdied.text = "\n Go!"

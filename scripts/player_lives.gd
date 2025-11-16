extends Node
#This Script Is What Globally Holds the Player Lives for the entire game session until either the game is beat or lost.
#Keep This In Mind-- When a Player beats a level(collecting all coints on the map) Give play 1+ life before going to next map.


var Player_Lives = 3
func reset():
	Player_Lives = 3

func lose_life():
	Player_Lives -= 1
	print("Lives Left: ",Player_Lives)

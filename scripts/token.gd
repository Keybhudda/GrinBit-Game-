class_name Token 
extends Area2D
#----------------------Scene and Other Node Connections ------------------------
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var game_manager: Node2D = %GameManager
@onready var game_state: Node2D = %GameState

#--------------------------Based Variables--------------------------------------
@export var token_id: String = ""
var collected := false

#----------------------Start Code ----------------------------------------------
func _ready() -> void:
	#Assign a consistent ID if not set manually
	if token_id == "":
		token_id = str(get_instance_id())
	
	add_to_group("Token")
	
	#register token with GameState
	game_state.register_item(token_id)
	
	#hide if already collected in the loaded state
	if game_state.collected_items.has(token_id) and game_state.collected_items[token_id]:
		queue_free()
	else:
		collected = false
		print("Token", token_id, " ready and registered.")
		

#----------------------Action Code----------------------------------------------
func _on_body_entered(_body) -> void:
	if collected:
		return #prevent Duplicate pickup
	collected = true
	print("Token", token_id, " collected!")
	
	game_manager.add_point() #add score
	game_state.collect_item(token_id, "token") # register collection
	
	animation_player.play("Pick up")

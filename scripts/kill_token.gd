class_name kill_token 
extends Area2D
#This Token Will Give Bonus Points But also Change The Game Mode From The Player(GrinBit) Being Chased to The Player chasing the enemies for a short period of time.
# Which during that time the player comes in contact with an enemies they shall get points and have the enemy have to rest themselves before returning back to normal mode.
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var game_state: Node2D = %GameState
@onready var game_manager: Node2D = %GameManager

@export var ktoken_id: String = ""
var collected := false


signal Activate_Chase

func _ready() -> void:
	#Assign a consistent ID if not set manually
	if ktoken_id == "":
		ktoken_id = str(get_instance_id())
	
	add_to_group("K-Tokens")
	
	#register ktoken with GameState
	game_state.register_item(ktoken_id)
	
	#hide if already collected in loaded state
	if game_state.collected_items.has(ktoken_id) and game_state.collected_items[ktoken_id]:
		queue_free()
	else:
		collected = false
		print("k-token", ktoken_id, " ready and registered.")


func _on_body_entered(_body) -> void:
	if collected:
		return #prevent Duplicated pickup
	
	collected = true
	print("ktoken", ktoken_id, " collected!")
	
	if _body.is_in_group("Player"):
		print("ktoken", ktoken_id, " triggered by player - emitting Activate_Chase")
		game_manager._on_chase_mode_activated()
		emit_signal("Activate_Chase") #Trigger Chase mode
	game_manager.add_point1()
	game_manager.Check_timer()
	game_state.collect_item(ktoken_id, "ktoken")# register collection
	
	
	animation_player.play("pick up")

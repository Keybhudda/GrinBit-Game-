extends Area2D
#----------------------Scene and Other Node Connections ------------------------
@onready var game_manager: Node = %GameManager
@onready var game_state: Node = %GameState
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var pickupsound: AudioStreamPlayer2D = $Pickupsound
@onready var animation_player: AnimationPlayer = $AnimationPlayer

#--------------------------Timers-----------------------------------------------
@onready var available_timer: Timer = $AvailableTimer

#----------------------Based Variables------------------------------------------
@export var food_id: String = ""
var collected := false
#----------------------Start Code ----------------------------------------------
func _ready() -> void:
	#Assign a consistent ID if not set manually
	if food_id == "":
		food_id = str(get_instance_id())
	
	add_to_group("foods")
	
	
	
	if game_state.collected_items.has(food_id) and game_state.collected_items[food_id]:
		queue_free()
	else:
		collected = false
		print("food_item", food_id, " ready and registered.")
	
	visible = false
	collision_shape_2d.disabled = true
	available_timer.start(10.0)
	
#----------------------Action Code----------------------------------------------
func _on_body_entered(_body) -> void:
	if collected:
		return #prevent Duplicated pickup
	collected = true
	print("food_item", food_id, " collected!")
	
	game_manager.add_pointf2()
	
	if get_tree().paused == true:
		pickupsound.stop()
		print("Stopping Sound")
		return
	
	animation_player.play("pickup")


func _on_available_timer_timeout() -> void:
	if visible == false and collision_shape_2d.disabled == true:
		visible = true
		collision_shape_2d.disabled = false
		available_timer.start(20.0)
	else:
		if visible == true and collision_shape_2d.disabled == false:
			visible = false
			collision_shape_2d.disabled = true
		

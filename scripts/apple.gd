extends Area2D
@onready var game_manager: Node = %GameManager
@onready var game_state: Node = %GameState
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var food_id: String = ""
var collected := false

func _ready() -> void:
	#Assign a consistent ID if not set manually
	if food_id == "":
		food_id = str(get_instance_id())
	
	add_to_group("foods")
	
	game_state.register_item(food_id)
	
	if game_state.collected_items.has(food_id) and game_state.collected_items[food_id]:
		queue_free()
	else:
		collected = false
		print("food_item", food_id, " ready and registered.")

func _on_body_entered(_body) -> void:
	if collected:
		return #prevent Duplicated pickup
	collected = true
	print("food_item", food_id, " collected!")
	
	game_manager.add_pointf2()
	game_state.collect_item(food_id, "foods")
	
	animation_player.play("pickup")

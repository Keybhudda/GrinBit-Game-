extends Area2D
#----------------------Scene and Other Node Connections ------------------------
@onready var game_manager: Node = %GameManager
@onready var game_state: Node = %GameState
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var pickupsound: AudioStreamPlayer2D = $Pickupsound

#--------------------------Timers-----------------------------------------------
@onready var available_timer: Timer = $AvailableTimer
@onready var pop_up_timer: Timer = $PopUpTimer

#----------------------Based Variables------------------------------------------
@export var food_id: String = ""
var collected := false

const GRID_SIZE = 16

var pop_spawned := false
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
	
	game_manager.add_pointf3()
	
	spawn_score_popup()
	
	if game_manager.current_state == game_manager.StateOfGame.DEAD:
		pickupsound.stop()
		print("Stopping Sound")
		return
	animation_player.play("pickup")
#used to pop up score of collect item.
var popup = preload("res://scenes/Menus & Pop Ups/UI-Assets/Score_popup.tscn").instantiate()

func display_points():
	var points = 600
	popup.visible = true
	@warning_ignore("integer_division")
	popup.position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	popup.set_score(points)
	pop_up_timer.start(2)

func spawn_score_popup():
	var points = 600
	get_tree().current_scene.add_child(popup)
	popup.visible = true
	@warning_ignore("integer_division")
	popup.position = position.snapped(Vector2(GRID_SIZE/2, GRID_SIZE/2))
	popup.set_score(points)
	pop_spawned = true
	pop_up_timer.start(2)

func _on_available_timer_timeout() -> void:
	if visible == false and collision_shape_2d.disabled == true:
		visible = true
		collision_shape_2d.disabled = false
		available_timer.start(20.0)
	else:
		if visible == true and collision_shape_2d.disabled == false:
			visible = false
			collision_shape_2d.disabled = true
		

func _on_pop_up_timer_timeout() -> void:
	if popup:
		popup.visible = false

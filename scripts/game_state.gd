extends Node
#This Script is used to keep tract of Game Data
#This Script Goes Hand & Hand With GameManger(GM) ->
# Where There is A Function That Saves all Game data when a death event happens to then resume from what is saved.


#----------------------Signals--------------------------------------------------
signal all_items_collected
signal k_tokens_ready(tokens: Array)
#-----------------------Base Variables------------------------------------------
var coins := 0
var kcoins := 0
var foods := 0
var collected_items: Dictionary = {}

var total_items := 0 #Total number of collectibles in the scene

var player_position: Vector2
var enemy_position: Dictionary = {}


#----------------------------Start Code-----------------------------------------
#game registering items that are collectable.
func register_item(id: String) -> void:
	#Called by tokens/foods in _ready() to register themselves.
	if not collected_items.has(id):
		collected_items[id] = false
	total_items = collected_items.size()
	print("Registered item:", id, "| Total items so far:", total_items)
	emit_signal("k_tokens_ready", get_tree().get_nodes_in_group("K-Tokens"))

#function for when item is collected 
func collect_item(id: String, type: String) -> void:
	#Called when a collectible is picked up
	if not collected_items.has(id):
		push_warning("Tried to collect unregistered item %s" % id)
		return
	if collected_items[id]:
		return
	collected_items[id] = true
	
	match type:
		"token":
			coins += 1
		"ktoken":
			kcoins += 1
		"foods":
			foods += 1
	
	print("Collected:", id, "| Type:", type)
	check_all_items_collected()

#checks if all items are collected if true will move to next level 
func check_all_items_collected() -> void:
	if collected_items.values().all(func(v): return v):
		print("All items collected! Level Complete!")
		emit_signal("all_items_collected")

#Stores item data
func store_state() -> Dictionary:
	#Save current item collection state
	return {
		"coins": coins,
		"kcoins": kcoins,
		"foods": foods,
		"collected_items": collected_items.duplicate(true)
		
	}

#loads item data
func load_state(saved_state: Dictionary) -> void:
	if saved_state.is_empty():
		return
	coins = saved_state.get("coins", 0)
	kcoins = saved_state.get("kcoins", 0)
	foods = saved_state.get("foods", 0)
	collected_items = saved_state.get("collected_items", {}).duplicate(true)

#Debug func for items registered
func debug_print_items() -> void:
	print("---Registered Items ---")
	for id in collected_items.keys():
		print(id, ":", collected_items[id])
	print("-----------------------")

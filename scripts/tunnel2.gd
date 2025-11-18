extends Area2D
#Tunnel Code Gives The Player The Ability To Go Through This Area and Come Out the other side of a connected Area.

#--------------------------Based Variables & Connections------------------------
@export var tunnel_id: String = "B"
@export var linked_tunnel: NodePath
@export var exit_offset: Vector2 = Vector2(0, 16)
const GRID_SIZE = 16

#----------------------Start Code ----------------------------------------------
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

#----------------------Action Code----------------------------------------------
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if linked_tunnel:
			var exit_tunnel = get_node(linked_tunnel)
			if exit_tunnel:
				var new_position = exit_tunnel.global_position + exit_offset
				@warning_ignore("integer_division")
				body.global_position = new_position.snapped(Vector2(GRID_SIZE, GRID_SIZE)) + Vector2(GRID_SIZE/2, GRID_SIZE/2)
				
				if body.has_method("stop_movement"):
					body.stop_movement()
					
				print("Teleported from tunnel", tunnel_id, "to", exit_tunnel.tunnel_id)

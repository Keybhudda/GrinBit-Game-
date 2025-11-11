extends Area2D


@export var tunnel_id: String = "B"
@export var linked_tunnel: NodePath
@export var exit_offset: Vector2 = Vector2(0, 16)
const GRID_SIZE = 16
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))


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

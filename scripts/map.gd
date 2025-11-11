extends TileMapLayer

@export var map_size: Vector2i = Vector2i(35, 20)
@export var obstacle_terrain_id: int = 3 # Tile ID or custon data flag for walls
@export var debug_draw: bool = true

var astar_grid: AStarGrid2D
var cell_size: Vector2 = Vector2i(16, 16)

var walkable_cells: Array[Vector2i] = []

func _ready() -> void:
	cell_size = tile_set.tile_size
	setup_astar_grid()
	print("Navigation grid built with AstarGrid2D", astar_grid.region)

func setup_astar_grid():
	var used_rect = get_used_rect()
	
	#Define grid region that matches yout map's cell dimensions 
	astar_grid = AStarGrid2D.new()
	astar_grid.region = used_rect
	astar_grid.cell_size = cell_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.update() #initialize
	
	walkable_cells.clear()
	
	#loop through all used tiles in the map
	for cell in get_used_cells():
		if not astar_grid.is_in_boundsv(cell):
			continue 
		
		var tile_data = get_cell_tile_data(cell)
		var _is_solid = true
		
		
		if tile_data:
			var has_nav = tile_data.get_navigation_polygon(0) != null
			_is_solid = not has_nav
			if tile_data.get_collision_polygons_count(0) > 0:
				_is_solid = true
			
		#only set points that exist in bounds
		
		astar_grid.set_point_solid(cell, _is_solid)
		if not _is_solid:
				walkable_cells.append(cell)
				
	astar_grid.update()
	print("AStarGrid built. Region:", astar_grid.region)
	print("Walkable cells count:", walkable_cells.size())

func get_astar_path(world_start: Vector2, world_end: Vector2) -> Array:
	if astar_grid == null:
		push_error("AstarGrid not built yet! Call setup_astar_grid() first.")
		return []
	
	var start_cell = local_to_map(to_local(world_start))
	var end_cell = local_to_map(to_local(world_end))
	
	
	
	if not astar_grid.is_in_boundsv(start_cell) or not astar_grid.is_in_boundsv(end_cell):
		return []
	
	if astar_grid.is_point_solid(start_cell) or astar_grid.is_point_solid(end_cell):
		return []
	
	var path_cells: Array[Vector2i] = astar_grid.get_id_path(start_cell, end_cell)
	if path_cells.is_empty():
		return []
		
	var world_path: Array[Vector2] = []
	for cell in path_cells:
		var world_pos = map_to_local(cell) 
		world_pos = world_pos
		world_path.append(to_global(world_pos))
		
	return world_path
	
func _draw() -> void:
	if not debug_draw or astar_grid == null:
		return
	
	var region_start = astar_grid.region.position
	var region_end = region_start + astar_grid.region.size
	
	for y in range(region_start.y, region_end.y):
		for x in range(region_start.x, region_end.x):
			var cell = Vector2i(x, y)
			if not astar_grid.is_in_boundsv(cell):
				continue
				
			var color = Color(0, 1, 0, 0.1) #Green = walkable
			if astar_grid.is_point_solid(cell):
				color = Color(1, 0, 0, 0.2) #Red = blocked
				
			var pos = map_to_local(cell) - (cell_size * 0.5)
			draw_rect(Rect2(pos, cell_size), color)
	for cell in get_used_cells():
		var tile_data = get_cell_tile_data(cell)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			for i in range(tile_data.get_collision_polygons_count(0)):
				var poly = tile_data.get_collision_polygon_points(0, i)
				if poly:
					var points: PackedVector2Array = []
					for p in poly:
						points.append(map_to_local(cell) + p)
					draw_polyline(points, Color(1, 1, 0, 0.8), 1.5)

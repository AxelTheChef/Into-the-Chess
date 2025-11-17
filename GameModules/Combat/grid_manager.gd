## grid_manager.gd - Grid 14x5 System
## Gestiona el sistema de coordenadas del tablero de combate
## MIGRADO: 7x7 → 14x5 (Vmin - Semana 1)

extends Node

# ============================================================================
# SIGNALS
# ============================================================================

signal tile_occupied(grid_pos: Vector2i, occupant: Node2D)
signal tile_freed(grid_pos: Vector2i)

# ============================================================================
# CONSTANTS
# ============================================================================

## Dimensiones del grid (tablero de ajedrez extendido)
const GRID_WIDTH: int = 14        ## 14 columnas (2 tableros lado a lado)
const GRID_HEIGHT: int = 5        ## 5 filas (lanes verticales)
const TILE_SIZE: int = 32         ## Tamaño de cada tile en píxeles

## Dimensiones de pantalla (referencia)
const SCREEN_WIDTH: int = 1280
const SCREEN_HEIGHT: int = 720

# ============================================================================
# VARIABLES
# ============================================================================

## Origen del grid en coordenadas de mundo (píxeles)
var grid_origin: Vector2 = Vector2.ZERO

## Diccionario de ocupación de tiles [Vector2i → Node2D]
var tile_occupancy: Dictionary = {}

# ============================================================================
# LIFECYCLE
# ============================================================================

func _init() -> void:
	print("[GridManager] Inicializando...")
	
	# Inicializar diccionario de ocupación
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			tile_occupancy[Vector2i(x, y)] = null
	
	print("  Grid: %dx%d tiles" % [GRID_WIDTH, GRID_HEIGHT])
	print("  Tile size: %dpx" % TILE_SIZE)
	print("  Grid pixel size: %dx%d" % [GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE])

func _ready() -> void:
	_calculate_grid_origin()
	print("[GridManager] Grid origin: %s" % grid_origin)
	print("[GridManager] Listo")

# ============================================================================
# GRID ORIGIN CALCULATION
# ============================================================================

func _calculate_grid_origin() -> void:
	"""Calcula el origen del grid para centrarlo en pantalla"""
	var screen_size := Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	var grid_pixel_width := GRID_WIDTH * TILE_SIZE   # 14 * 32 = 448px
	var grid_pixel_height := GRID_HEIGHT * TILE_SIZE  # 5 * 32 = 160px
	
	# Centrar grid en pantalla
	grid_origin.x = (screen_size.x - grid_pixel_width) / 2.0
	grid_origin.y = (screen_size.y - grid_pixel_height) / 2.0
	
	# Redondear para evitar sub-píxeles
	grid_origin = grid_origin.floor()

# ============================================================================
# COORDINATE CONVERSION
# ============================================================================

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""
	Convierte coordenadas de grid a coordenadas de mundo (píxeles).
	Retorna el centro del tile.
	
	Args:
		grid_pos: Posición en el grid (x, y)
	
	Returns:
		Posición en píxeles (centro del tile)
	
	Example:
		var world_pos = GridManager.grid_to_world(Vector2i(7, 2))
	"""
	var world_x := grid_origin.x + (grid_pos.x * TILE_SIZE) + (TILE_SIZE / 2.0)
	var world_y := grid_origin.y + (grid_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	return Vector2(world_x, world_y)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""
	Convierte coordenadas de mundo (píxeles) a coordenadas de grid.
	
	Args:
		world_pos: Posición en píxeles
	
	Returns:
		Posición en el grid (x, y)
	
	Example:
		var grid_pos = GridManager.world_to_grid(mouse_position)
	"""
	var relative_x := world_pos.x - grid_origin.x
	var relative_y := world_pos.y - grid_origin.y
	
	var grid_x := int(relative_x / TILE_SIZE)
	var grid_y := int(relative_y / TILE_SIZE)
	
	return Vector2i(grid_x, grid_y)

# ============================================================================
# VALIDATION
# ============================================================================

func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	"""
	Valida si una posición está dentro de los límites del grid.
	
	Args:
		grid_pos: Posición a validar
	
	Returns:
		true si está dentro del grid, false si no
	
	Example:
		if GridManager.is_valid_grid_pos(target_pos):
			move_to(target_pos)
	"""
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and \
		   grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT

func is_position_valid(grid_pos: Vector2i) -> bool:
	"""Alias de is_valid_grid_pos() para compatibilidad"""
	return is_valid_grid_pos(grid_pos)

func is_tile_occupied(grid_pos: Vector2i) -> bool:
	"""
	Verifica si un tile está ocupado.
	
	Args:
		grid_pos: Posición del tile
	
	Returns:
		true si está ocupado, false si está libre
	"""
	if not is_valid_grid_pos(grid_pos):
		return true  # Fuera de límites cuenta como ocupado
	
	return tile_occupancy.get(grid_pos) != null

func is_tile_free(grid_pos: Vector2i) -> bool:
	"""Retorna true si el tile está libre (no ocupado)"""
	return not is_tile_occupied(grid_pos)

# ============================================================================
# TILE OCCUPANCY
# ============================================================================

func occupy_tile(grid_x: int, grid_y: int, occupant: Node2D) -> bool:
	"""
	Marca un tile como ocupado por un objeto.
	
	Args:
		grid_x: Coordenada X en el grid
		grid_y: Coordenada Y en el grid
		occupant: Nodo que ocupa el tile
	
	Returns:
		true si se ocupó exitosamente, false si ya estaba ocupado
	
	Example:
		if GridManager.occupy_tile(5, 3, piece_node):
			print("Tile ocupado exitosamente")
	"""
	var grid_pos := Vector2i(grid_x, grid_y)
	
	if not is_valid_grid_pos(grid_pos):
		push_warning("[GridManager] Intento de ocupar tile inválido: %s" % grid_pos)
		return false
	
	if is_tile_occupied(grid_pos):
		push_warning("[GridManager] Tile ya ocupado: %s" % grid_pos)
		return false
	
	tile_occupancy[grid_pos] = occupant
	tile_occupied.emit(grid_pos, occupant)
	return true

func free_tile(grid_x: int, grid_y: int) -> bool:
	"""
	Libera un tile ocupado.
	
	Args:
		grid_x: Coordenada X en el grid
		grid_y: Coordenada Y en el grid
	
	Returns:
		true si se liberó exitosamente, false si ya estaba libre
	
	Example:
		GridManager.free_tile(old_x, old_y)
	"""
	var grid_pos := Vector2i(grid_x, grid_y)
	
	if not is_valid_grid_pos(grid_pos):
		push_warning("[GridManager] Intento de liberar tile inválido: %s" % grid_pos)
		return false
	
	if not is_tile_occupied(grid_pos):
		return false  # Ya estaba libre
	
	tile_occupancy[grid_pos] = null
	tile_freed.emit(grid_pos)
	return true

func get_tile_occupant(grid_pos: Vector2i) -> Node2D:
	"""
	Retorna el objeto que ocupa un tile (o null si está libre).
	
	Args:
		grid_pos: Posición del tile
	
	Returns:
		Node2D que ocupa el tile, o null si está libre
	"""
	if not is_valid_grid_pos(grid_pos):
		return null
	
	return tile_occupancy.get(grid_pos)

# ============================================================================
# PATHFINDING HELPERS
# ============================================================================

func get_neighbors(grid_pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	"""
	Retorna las posiciones vecinas válidas de un tile.
	
	Args:
		grid_pos: Posición central
		diagonal: Si true, incluye diagonales (8 vecinos), si false solo ortogonales (4)
	
	Returns:
		Array de posiciones vecinas válidas
	"""
	var neighbors: Array[Vector2i] = []
	
	# Direcciones ortogonales (arriba, abajo, izquierda, derecha)
	var orthogonal := [
		Vector2i(0, -1),   # Arriba
		Vector2i(0, 1),    # Abajo
		Vector2i(-1, 0),   # Izquierda
		Vector2i(1, 0)     # Derecha
	]
	
	# Direcciones diagonales
	var diagonals := [
		Vector2i(-1, -1),  # Arriba-Izquierda
		Vector2i(1, -1),   # Arriba-Derecha
		Vector2i(-1, 1),   # Abajo-Izquierda
		Vector2i(1, 1)     # Abajo-Derecha
	]
	
	var directions := orthogonal
	if diagonal:
		directions.append_array(diagonals)
	
	for dir in directions:
		var neighbor: Vector2i = grid_pos + dir
		if is_valid_grid_pos(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func get_distance_manhattan(pos1: Vector2i, pos2: Vector2i) -> int:
	"""
	Calcula distancia Manhattan entre dos posiciones.
	
	Args:
		pos1: Primera posición
		pos2: Segunda posición
	
	Returns:
		Distancia Manhattan (suma de diferencias absolutas)
	"""
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

# ============================================================================
# DEBUG
# ============================================================================

func print_occupancy_status() -> void:
	"""Imprime el estado de ocupación del grid (debug)"""
	print("[GridManager] Estado de ocupación:")
	var occupied_count := 0
	
	for y in range(GRID_HEIGHT):
		var row := ""
		for x in range(GRID_WIDTH):
			var pos := Vector2i(x, y)
			if is_tile_occupied(pos):
				row += "X "
				occupied_count += 1
			else:
				row += ". "
		print("  " + row)
	
	print("  Tiles ocupados: %d / %d" % [occupied_count, GRID_WIDTH * GRID_HEIGHT])

# ============================================================================
# TESTING HELPERS
# ============================================================================

func test_grid_modifications() -> void:
	"""
	Función de testing para validar modificabilidad del sistema.
	Ejecutar manualmente después de cambiar GRID_WIDTH/GRID_HEIGHT.
	"""
	print("=== GRID MODIFICATION TEST ===")
	print("Current grid: %dx%d" % [GRID_WIDTH, GRID_HEIGHT])
	print("Grid pixel size: %dx%d" % [GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE])
	print("Grid origin: %s" % grid_origin)
	
	# Test conversiones en esquinas
	var corners := [
		Vector2i(0, 0),                           # Top-left
		Vector2i(GRID_WIDTH - 1, 0),             # Top-right
		Vector2i(0, GRID_HEIGHT - 1),            # Bottom-left
		Vector2i(GRID_WIDTH - 1, GRID_HEIGHT - 1) # Bottom-right
	]
	
	print("\nTesting corner conversions:")
	for corner in corners:
		var world := grid_to_world(corner)
		var back := world_to_grid(world)
		var match_str := "✅" if corner == back else "❌"
		print("  %s → %s → %s %s" % [corner, world, back, match_str])
	
	# Test validación límites
	print("\nTesting boundary validation:")
	var last_valid := Vector2i(GRID_WIDTH - 1, GRID_HEIGHT - 1)
	var invalid_x := Vector2i(GRID_WIDTH, 0)
	var invalid_y := Vector2i(0, GRID_HEIGHT)
	
	print("  %s valid: %s (expected: true)" % [last_valid, is_valid_grid_pos(last_valid)])
	print("  %s valid: %s (expected: false)" % [invalid_x, is_valid_grid_pos(invalid_x)])
	print("  %s valid: %s (expected: false)" % [invalid_y, is_valid_grid_pos(invalid_y)])
	
	print("==============================")

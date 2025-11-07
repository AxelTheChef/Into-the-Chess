extends Node
"""
Grid Manager - Mutation Garden Defense
Role: ASISTENTE 1 - Grid System & Coordenadas
Version: 2.0 - Actualizado para MGD Roguelike
Godot: 4.5

CAMBIOS vs versión anterior:
- Añadido: Sistema de centrado automático en pantalla 1280x720
- Añadido: Señales de input (tile_clicked, tile_hovered)
- Mejorado: Conversión grid↔world considera offset de centrado
- Mantenido: Sistema de ocupación de tiles (útil para plantas)
- Optimizado: Para funcionar como Singleton (Autoload)

DEPENDENCIES:
- Ninguna (sistema base)

SIGNALS EMITTED:
- tile_occupied(grid_pos: Vector2i, occupant: Node2D)
- tile_freed(grid_pos: Vector2i)
- tile_clicked(grid_pos: Vector2i)          [NUEVO]
- tile_hovered(grid_pos: Vector2i)          [NUEVO]

PUBLIC API:
- grid_to_world(grid_pos: Vector2i) -> Vector2
- world_to_grid(world_pos: Vector2) -> Vector2i
- is_valid_grid_pos(grid_pos: Vector2i) -> bool
- is_position_occupied(grid_x: int, grid_y: int) -> bool
- occupy_tile(grid_x: int, grid_y: int, occupant: Node2D) -> bool
- free_tile(grid_x: int, grid_y: int) -> bool
- get_tile_occupant(grid_x: int, grid_y: int) -> Node2D
- get_neighbors(grid_pos: Vector2i) -> Array[Vector2i]
"""

# ========================================
# CONSTANTES
# ========================================
const GRID_SIZE: int = 7          # Grid 7x7
const TILE_SIZE: int = 32         # Cada tile 32x32px
const SCREEN_WIDTH: int = 1280    # Resolución proyecto
const SCREEN_HEIGHT: int = 720

# ========================================
# VARIABLES PÚBLICAS
# ========================================
var grid_origin: Vector2 = Vector2.ZERO  # Calculado en _ready()

# ========================================
# SEÑALES
# ========================================
signal tile_occupied(grid_pos: Vector2i, occupant: Node2D)
signal tile_freed(grid_pos: Vector2i)
signal tile_clicked(grid_pos: Vector2i)
signal tile_hovered(grid_pos: Vector2i)

# ========================================
# VARIABLES PRIVADAS
# ========================================
var _occupied_tiles: Dictionary = {}  # Vector2i -> Node2D
var _last_hovered_tile: Vector2i = Vector2i(-1, -1)

# ========================================
# LIFECYCLE
# ========================================
func _ready() -> void:
	add_to_group("grid_manager")
	_calculate_grid_origin()
	_initialize_grid()
	
	print("[GridManager] ✓ Inicializado")
	print("  Grid: %dx%d tiles" % [GRID_SIZE, GRID_SIZE])
	print("  Tile size: %dpx" % TILE_SIZE)
	print("  Grid origin: %s" % grid_origin)
	print("  Grid pixel size: %dx%d" % [GRID_SIZE * TILE_SIZE, GRID_SIZE * TILE_SIZE])

func _calculate_grid_origin() -> void:
	"""Calcula origen del grid para centrarlo en pantalla 1280x720"""
	var screen_size := Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	var grid_pixel_size := GRID_SIZE * TILE_SIZE  # 7 * 32 = 224px
	
	# Centrar grid en pantalla
	grid_origin = (screen_size - Vector2(grid_pixel_size, grid_pixel_size)) / 2
	
	# Redondear para evitar píxeles fraccionarios
	grid_origin = grid_origin.floor()

func _initialize_grid() -> void:
	"""Inicializa el sistema de tiles"""
	_occupied_tiles.clear()

# ========================================
# INPUT HANDLING (NUEVO)
# ========================================
func _input(event: InputEvent) -> void:
	"""Detecta clicks y hover sobre el grid"""
	
	# Mouse motion para hover
	if event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)
	
	# Click para selección
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_mouse_click(event.position)

func _handle_mouse_hover(mouse_pos: Vector2) -> void:
	"""Maneja hover sobre tiles"""
	var grid_pos := world_to_grid(mouse_pos)
	
	# Solo emitir si cambió de tile
	if is_valid_grid_pos(grid_pos) and grid_pos != _last_hovered_tile:
		_last_hovered_tile = grid_pos
		tile_hovered.emit(grid_pos)

func _handle_mouse_click(mouse_pos: Vector2) -> void:
	"""Maneja clicks sobre tiles"""
	var grid_pos := world_to_grid(mouse_pos)
	
	if is_valid_grid_pos(grid_pos):
		tile_clicked.emit(grid_pos)
		print("[GridManager] Tile clicked: %s" % grid_pos)

# ========================================
# CONVERSIÓN DE COORDENADAS (MEJORADO)
# ========================================
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""
	Convierte coordenadas grid a píxeles mundo (centro del tile)
	Args:
		grid_pos: Posición en grid (0-6, 0-6)
	Returns:
		Vector2 con posición mundial centrada en el tile
	"""
	var world_x := grid_origin.x + (grid_pos.x * TILE_SIZE) + (TILE_SIZE / 2.0)
	var world_y := grid_origin.y + (grid_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	return Vector2(world_x, world_y)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""
	Convierte píxeles mundo a coordenadas grid
	Args:
		world_pos: Posición en coordenadas mundiales
	Returns:
		Vector2i con coordenadas de grid
	"""
	var grid_x := int((world_pos.x - grid_origin.x) / TILE_SIZE)
	var grid_y := int((world_pos.y - grid_origin.y) / TILE_SIZE)
	return Vector2i(grid_x, grid_y)

func get_tile_center(grid_pos: Vector2i) -> Vector2:
	"""Alias de grid_to_world (claridad semántica)"""
	return grid_to_world(grid_pos)

# ========================================
# VALIDACIÓN
# ========================================
func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	"""
	Verifica si coordenada está dentro del grid (0-6)
	Args:
		grid_pos: Posición de grid a validar
	Returns:
		true si está dentro del grid
	"""
	return grid_pos.x >= 0 and grid_pos.x < GRID_SIZE and \
		   grid_pos.y >= 0 and grid_pos.y < GRID_SIZE

func is_position_valid(grid_x: int, grid_y: int) -> bool:
	"""Versión legacy (compatibilidad)"""
	return is_valid_grid_pos(Vector2i(grid_x, grid_y))

func is_position_occupied(grid_x: int, grid_y: int) -> bool:
	"""
	Verifica si un tile está ocupado
	Args:
		grid_x: Coordenada X del grid
		grid_y: Coordenada Y del grid
	Returns:
		true si el tile está ocupado
	"""
	if not is_position_valid(grid_x, grid_y):
		return false
	
	var grid_pos := Vector2i(grid_x, grid_y)
	return _occupied_tiles.has(grid_pos)

# ========================================
# GESTIÓN DE OCUPACIÓN (MANTENIDO)
# ========================================
func occupy_tile(grid_x: int, grid_y: int, occupant: Node2D) -> bool:
	"""
	Marca un tile como ocupado
	Args:
		grid_x: Coordenada X del grid
		grid_y: Coordenada Y del grid
		occupant: Nodo que ocupa el tile
	Returns:
		true si se ocupó exitosamente
	"""
	if not is_position_valid(grid_x, grid_y):
		push_warning("[GridManager] Posición inválida: (%d, %d)" % [grid_x, grid_y])
		return false
	
	var grid_pos := Vector2i(grid_x, grid_y)
	
	if _occupied_tiles.has(grid_pos):
		push_warning("[GridManager] Tile (%d, %d) ya ocupado por: %s" % 
					[grid_x, grid_y, _occupied_tiles[grid_pos].name])
		return false
	
	_occupied_tiles[grid_pos] = occupant
	tile_occupied.emit(grid_pos, occupant)
	return true

func free_tile(grid_x: int, grid_y: int) -> bool:
	"""
	Libera un tile ocupado
	Args:
		grid_x: Coordenada X del grid
		grid_y: Coordenada Y del grid
	Returns:
		true si se liberó exitosamente
	"""
	var grid_pos := Vector2i(grid_x, grid_y)
	
	if not _occupied_tiles.has(grid_pos):
		return false
	
	_occupied_tiles.erase(grid_pos)
	tile_freed.emit(grid_pos)
	return true

func get_tile_occupant(grid_x: int, grid_y: int) -> Node2D:
	"""
	Obtiene el objeto que ocupa un tile
	Args:
		grid_x: Coordenada X del grid
		grid_y: Coordenada Y del grid
	Returns:
		Node2D ocupante, o null si está vacío
	"""
	var grid_pos := Vector2i(grid_x, grid_y)
	return _occupied_tiles.get(grid_pos, null)

func get_all_occupied_tiles() -> Array[Vector2i]:
	"""
	Obtiene lista de todos los tiles ocupados
	Returns:
		Array con todas las posiciones ocupadas
	"""
	var occupied: Array[Vector2i] = []
	for grid_pos in _occupied_tiles.keys():
		occupied.append(grid_pos)
	return occupied

func clear_all_tiles() -> void:
	"""Limpia todos los tiles ocupados (útil para reset)"""
	_occupied_tiles.clear()
	print("[GridManager] Todos los tiles liberados")

# ========================================
# UTILIDADES (MANTENIDO Y MEJORADO)
# ========================================
func get_neighbors(grid_pos: Vector2i, include_diagonals: bool = false) -> Array[Vector2i]:
	"""
	Retorna tiles adyacentes (4-direccionales por defecto)
	Args:
		grid_pos: Posición central
		include_diagonals: Si true, incluye 8 direcciones
	Returns:
		Array con vecinos válidos
	"""
	var neighbors: Array[Vector2i] = []
	var directions := [
		Vector2i(0, -1),   # Arriba
		Vector2i(1, 0),    # Derecha
		Vector2i(0, 1),    # Abajo
		Vector2i(-1, 0)    # Izquierda
	]
	
	if include_diagonals:
		directions.append_array([
			Vector2i(-1, -1),  # Diagonal superior izquierda
			Vector2i(1, -1),   # Diagonal superior derecha
			Vector2i(-1, 1),   # Diagonal inferior izquierda
			Vector2i(1, 1)     # Diagonal inferior derecha
		])
	
	for dir in directions:
		var neighbor: Vector2i = grid_pos + dir
		if is_valid_grid_pos(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func get_distance_between(pos1: Vector2i, pos2: Vector2i) -> int:
	"""
	Calcula distancia Manhattan entre dos posiciones
	Args:
		pos1: Primera posición
		pos2: Segunda posición
	Returns:
		Distancia Manhattan (sin diagonales)
	"""
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

# ========================================
# DEBUG
# ========================================
func print_grid_state() -> void:
	"""Imprime estado actual del grid"""
	print("=== GRID STATE ===")
	print("Grid origin: %s" % grid_origin)
	print("Occupied tiles: %d" % _occupied_tiles.size())
	for grid_pos in _occupied_tiles.keys():
		var occupant = _occupied_tiles[grid_pos]
		var world_pos = grid_to_world(grid_pos)
		print("  %s -> %s (world: %s)" % [grid_pos, occupant.name, world_pos])
	print("==================")

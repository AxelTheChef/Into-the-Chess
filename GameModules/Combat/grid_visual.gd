## grid_visual.gd - Grid Visual Renderer
## Renderiza el grid 14x5 usando TileMapLayer
## MIGRADO: 7x7 → 14x5 (Vmin - Semana 1)

extends TileMapLayer

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	# Posicionar el TileMapLayer en el grid_origin
	position = GridManager.grid_origin
	
	# Configurar rendering
	modulate = Color(1, 1, 1, 0.3)  # 30% opacidad
	z_index = -1  # Detrás de todo
	
	_draw_grid()
	
	print("[GridVisual] Posicionado en: %s" % position)

# ============================================================================
# GRID RENDERING
# ============================================================================

func _draw_grid() -> void:
	"""
	Dibuja el grid completo usando el TileMapLayer.
	Actualizado para grid 14x5.
	"""
	clear()
	
	# Pintar grid 14x5
	for x in range(GridManager.GRID_WIDTH):
		for y in range(GridManager.GRID_HEIGHT):
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
	print("[GridVisual] Grid %dx%d dibujado (%d tiles)" % [
		GridManager.GRID_WIDTH, 
		GridManager.GRID_HEIGHT,
		GridManager.GRID_WIDTH * GridManager.GRID_HEIGHT
	])

# ============================================================================
# VISUAL FEEDBACK
# ============================================================================

func highlight_tile(grid_pos: Vector2i, color: Color = Color.YELLOW) -> void:
	"""
	Resalta un tile con un color específico.
	
	Args:
		grid_pos: Posición del tile a resaltar
		color: Color del resaltado (default: amarillo)
	"""
	if not GridManager.is_valid_grid_pos(grid_pos):
		return
	
	# Cambiar el modulate del tile (requiere configuración en TileSet)
	# Implementación básica: cambiar color de capa
	modulate = color

func clear_highlights() -> void:
	"""Limpia todos los resaltados visuales"""
	modulate = Color.WHITE

# ============================================================================
# DEBUG
# ============================================================================

func redraw_grid() -> void:
	"""Redibuja el grid (útil después de cambios dinámicos)"""
	_draw_grid()

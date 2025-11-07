extends TileMapLayer

"""
GridVisual - Visualización del Grid 7x7
Se posiciona automáticamente usando GridManager.grid_origin
"""

func _ready() -> void:
	# CRÍTICO: Posicionar el TileMapLayer en el grid_origin
	# Esto hace que el tile (0,0) del TileMap coincida con el grid (0,0) del GridManager
	position = GridManager.grid_origin
	
	# Configurar rendering
	modulate = Color(1, 1, 1, 0.3)  # 30% opacidad
	z_index = -1  # Detrás de todo
	
	# Dibujar el grid
	_draw_grid()
	
	print("[GridVisual] Posicionado en: %s" % position)

func _draw_grid() -> void:
	"""Dibuja el grid 7x7"""
	
	# Limpiar tiles existentes
	clear()
	
	# Pintar grid 7x7
	for x in range(GridManager.GRID_SIZE):
		for y in range(GridManager.GRID_SIZE):
			# Tile source_id = 0, atlas_coords = (0, 0)
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
	print("[GridVisual] Grid 7x7 dibujado")

func highlight_tile(grid_pos: Vector2i, color: Color = Color.YELLOW) -> void:
	"""Resalta un tile específico (útil para debugging/hover)"""
	if GridManager.is_valid_grid_pos(grid_pos):
		# Cambiar el modulate de un tile específico
		# Nota: Esto requiere crear una variante del tile
		pass  # Implementar después si es necesario

func clear_highlights() -> void:
	"""Limpia todos los resaltados"""
	pass  # Implementar después si es necesario

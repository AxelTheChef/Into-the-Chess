extends CharacterBody2D
class_name AvatarBase

"""
AvatarBase - Clase padre de todos los avatares
Role: ASISTENTE 1 - Avatar System
Version: 1.0

Maneja:
- Movimiento tile-by-tile en grid
- Posicionamiento en coordenadas de grid
- Sistema de selección
- Animaciones de movimiento (tweens)

DEPENDENCIES:
- GridManager (global)

SIGNALS:
- movement_started(from: Vector2i, to: Vector2i)
- movement_finished(grid_pos: Vector2i)
- avatar_selected()
- avatar_deselected()

PUBLIC API:
- move_to_grid(target: Vector2i) -> bool
- teleport_to_grid(grid_pos: Vector2i)
- get_grid_position() -> Vector2i
- select() / deselect()
"""

# ========================================
# PROPIEDADES EXPORTADAS
# ========================================
@export var avatar_name: String = "Avatar"
@export var move_speed: float = 200.0  ## Píxeles por segundo
@export var arms_count: int = 4        ## Número de brazos (para plantas)

# ========================================
# POSICIÓN EN GRID
# ========================================
var grid_position: Vector2i = Vector2i(3, 3)     ## Posición actual en grid
var target_grid_position: Vector2i = Vector2i(3, 3)  ## Destino de movimiento
var is_moving: bool = false

# ========================================
# ESTADO
# ========================================
var is_selected: bool = false

# ========================================
# COMPONENTES (para otros asistentes)
# ========================================
var stats_manager: Node = null      ## Asistente 2 - Stats
var equipment_manager: Node = null  ## Asistente 3 - Plantas

# ========================================
# SEÑALES
# ========================================
signal movement_started(from: Vector2i, to: Vector2i)
signal movement_finished(grid_pos: Vector2i)
signal avatar_selected()
signal avatar_deselected()

# ========================================
# REFERENCIAS INTERNAS
# ========================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var selection_indicator: Node2D = $SelectionIndicator

# ========================================
# LIFECYCLE
# ========================================
func _ready() -> void:
	add_to_group("avatars")
	
	# Posicionar en grid inicial
	teleport_to_grid(grid_position)
	
	# Buscar componentes opcionales
	_find_components()
	
	# Ocultar indicador de selección
	if selection_indicator:
		selection_indicator.visible = false
	
	print("[%s] Avatar inicializado en %s" % [avatar_name, grid_position])

func _find_components() -> void:
	"""Busca componentes opcionales añadidos por otros asistentes"""
	stats_manager = get_node_or_null("StatsManager")
	equipment_manager = get_node_or_null("EquipmentManager")

# ========================================
# MOVIMIENTO
# ========================================
func move_to_grid(target: Vector2i) -> bool:
	"""
	Intenta mover avatar a tile target con animación
	Args:
		target: Posición de grid destino
	Returns:
		true si movimiento inició, false si no es posible
	"""
	# Validar tile
	if not GridManager.is_valid_grid_pos(target):
		print("[%s] Tile inválido: %s" % [avatar_name, target])
		return false
	
	# No mover si ya está en movimiento
	if is_moving:
		print("[%s] Ya está en movimiento" % avatar_name)
		return false
	
	# No mover si ya está en esa posición
	if target == grid_position:
		return false
	
	# Verificar que tile esté libre (walkable)
	if not _is_tile_walkable(target):
		print("[%s] Tile ocupado: %s" % [avatar_name, target])
		return false
	
	# Iniciar movimiento
	target_grid_position = target
	_start_movement()
	return true

func _is_tile_walkable(grid_pos: Vector2i) -> bool:
	"""
	Verifica si tile está libre para caminar
	Args:
		grid_pos: Posición de grid a verificar
	Returns:
		true si el tile está libre
	"""
	# TODO: Implementar collision detection con plantas/enemigos
	# Por ahora, solo verificar límites del grid
	return GridManager.is_valid_grid_pos(grid_pos)

func _start_movement() -> void:
	"""Inicia animación de movimiento hacia target_grid_position"""
	is_moving = true
	movement_started.emit(grid_position, target_grid_position)
	
	# Calcular dirección para voltear sprite
	var direction: Vector2i = target_grid_position - grid_position
	_update_facing_direction(direction)
	
	# Obtener posición mundo del destino
	var target_world: Vector2 = GridManager.grid_to_world(target_grid_position)
	
	# Calcular duración del tween
	var distance: float = global_position.distance_to(target_world)
	var duration: float = distance / move_speed
	
	# Crear tween con easing suave
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "global_position", target_world, duration)
	tween.finished.connect(_on_movement_finished)
	
	# TODO: Activar animación de walk (cuando tengamos AnimationPlayer)
	# if animation_player and animation_player.has_animation("walk"):
	#     animation_player.play("walk")

func _on_movement_finished() -> void:
	"""Callback cuando termina el tween de movimiento"""
	grid_position = target_grid_position
	is_moving = false
	movement_finished.emit(grid_position)
	
	# TODO: Volver a animación idle
	# if animation_player and animation_player.has_animation("idle"):
	#     animation_player.play("idle")

func _update_facing_direction(direction: Vector2i) -> void:
	"""
	Voltea sprite según dirección de movimiento
	Args:
		direction: Vector de dirección del movimiento
	"""
	if sprite:
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false
		# Si solo hay movimiento vertical (y), no cambiar flip

func teleport_to_grid(grid_pos: Vector2i) -> void:
	"""
	Teleporta avatar a posición sin animación
	Útil para inicio de sala o respawn
	Args:
		grid_pos: Posición de grid destino
	"""
	if GridManager.is_valid_grid_pos(grid_pos):
		grid_position = grid_pos
		target_grid_position = grid_pos
		global_position = GridManager.grid_to_world(grid_pos)
		is_moving = false
		print("[%s] Teleportado a %s" % [avatar_name, grid_pos])

# ========================================
# SELECCIÓN
# ========================================
func select() -> void:
	"""Marca avatar como seleccionado"""
	if is_selected:
		return
	
	is_selected = true
	avatar_selected.emit()
	_update_visual_selection()
	
	print("[%s] Seleccionado" % avatar_name)

func deselect() -> void:
	"""Desmarca avatar como seleccionado"""
	if not is_selected:
		return
	
	is_selected = false
	avatar_deselected.emit()
	_update_visual_selection()
	
	print("[%s] Deseleccionado" % avatar_name)

func _update_visual_selection() -> void:
	"""Actualiza feedback visual de selección"""
	if is_selected:
		# Hacer sprite más brillante
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.2)
		
		# Mostrar indicador de selección
		if selection_indicator:
			selection_indicator.visible = true
	else:
		# Volver a color normal
		if sprite:
			sprite.modulate = Color(1, 1, 1)
		
		# Ocultar indicador
		if selection_indicator:
			selection_indicator.visible = false

# ========================================
# INPUT (Detección de click en avatar)
# ========================================
func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	"""Detecta clicks sobre el avatar"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Click en avatar → Intentar seleccionar
			_on_avatar_clicked()

func _on_avatar_clicked() -> void:
	"""Callback cuando se clickea el avatar"""
	# Emitir señal para que AvatarManager lo maneje
	# (Se implementará en Semana 2)
	print("[%s] Click detectado" % avatar_name)

# ========================================
# API PÚBLICA
# ========================================
func get_grid_position() -> Vector2i:
	"""Obtiene posición actual en grid"""
	return grid_position

func can_move() -> bool:
	"""Verifica si el avatar puede moverse"""
	return not is_moving

# ========================================
# DEBUG
# ========================================
func _draw() -> void:
	"""Dibuja debug info (solo si es necesario)"""
	if OS.is_debug_build() and is_selected:
		# Dibujar círculo en posición del avatar
		draw_circle(Vector2.ZERO, 20, Color(1, 1, 0, 0.3))

func print_status() -> void:
	"""Imprime estado del avatar (debugging)"""
	print("=== %s STATUS ===" % avatar_name)
	print("  Grid pos: %s" % grid_position)
	print("  World pos: %s" % global_position)
	print("  Is moving: %s" % is_moving)
	print("  Is selected: %s" % is_selected)
	print("  Arms: %d" % arms_count)
	print("================")

extends Node2D

"""
Test Scene - Avatar Movement con InputManager
Versión 2.0 - Usa sistema centralizado de input
"""

# ========================================
# REFERENCIAS
# ========================================
var avatar: AvatarBase = null

# ========================================
# LIFECYCLE
# ========================================
func _ready() -> void:
	# Instanciar avatar
	var avatar_scene: PackedScene = preload("res://GameModules/Avatar/avatar_queen.tscn")
	avatar = avatar_scene.instantiate()
	add_child(avatar)
	
	
	
	
	# Posicionar en centro del grid
	avatar.teleport_to_grid(Vector2i(3, 3))
	
	# Seleccionar avatar
	avatar.select()
	
	# Conectar señales del avatar
	avatar.movement_started.connect(_on_avatar_movement_started)
	avatar.movement_finished.connect(_on_avatar_movement_finished)
	
	# Conectar señales del InputManager
	InputManager.movement_input.connect(_on_movement_input)
	InputManager.tile_selected.connect(_on_tile_selected)
	InputManager.action_pressed.connect(_on_action_pressed)
	
	_print_instructions()

func _print_instructions() -> void:
	"""Imprime instrucciones de uso"""
	print("\n=== AVATAR MOVEMENT TEST v2.0 ===")
	print("Controles PC:")
	print("  WASD o Flechas: Mover avatar")
	print("  Click en tile: Mover a ese tile")
	print("  ESPACIO: Acción primaria (placeholder)")
	print("  TAB: Cambiar avatar (placeholder)")
	print("  SHIFT: Toggle control mode (placeholder)")
	print("  P: Imprimir estado del avatar")
	print("  I: Imprimir estado del InputManager")
	
	if InputManager.mobile_controls != null:
		InputManager.mobile_controls.visible = true
		print("[TEST] Joystick visible para testing")
	
	print("===================================\n")

# ========================================
# INPUT CALLBACKS
# ========================================
func _on_movement_input(direction: Vector2i) -> void:
	"""Callback cuando InputManager detecta movimiento"""
	if not avatar or not avatar.can_move():
		return
	
	# Calcular posición destino
	var current_pos: Vector2i = avatar.get_grid_position()
	var target_pos: Vector2i = current_pos + direction
	
	# Intentar mover
	avatar.move_to_grid(target_pos)

func _on_tile_selected(grid_pos: Vector2i) -> void:
	"""Callback cuando se selecciona un tile"""
	if not avatar or not avatar.can_move():
		return
	
	# Mover avatar al tile seleccionado
	avatar.move_to_grid(grid_pos)

func _on_action_pressed(action_name: String) -> void:
	"""Callback cuando se presiona una acción especial"""
	match action_name:
		"action_primary":
			print("[TEST] Acción primaria (no implementada)")
		
		"cycle_avatar":
			print("[TEST] Cambiar avatar (no implementado - Semana 2)")
		
		"toggle_control_mode":
			print("[TEST] Toggle control mode (no implementado - Semana 2)")

# ========================================
# INPUT ADICIONAL (DEBUGGING)
# ========================================
func _input(event: InputEvent) -> void:
	"""Input adicional para comandos de debugging"""
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_P:
				# Imprimir estado del avatar
				if avatar:
					avatar.print_status()
			
			KEY_I:
				# Imprimir estado del InputManager
				InputManager.print_input_state()

# ========================================
# AVATAR CALLBACKS
# ========================================
func _on_avatar_movement_started(from: Vector2i, to: Vector2i) -> void:
	"""Callback cuando avatar inicia movimiento"""
	print("[TEST] Movimiento iniciado: %s → %s" % [from, to])

func _on_avatar_movement_finished(grid_pos: Vector2i) -> void:
	"""Callback cuando avatar termina movimiento"""
	print("[TEST] Movimiento completado en: %s" % grid_pos)

# ========================================
# DEBUG DRAW
# ========================================
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	"""Dibuja info de debugging"""
	if not avatar:
		return
	
	# Línea desde avatar a mouse (próximo movimiento potencial)
	var mouse_pos: Vector2 = get_global_mouse_position()
	var mouse_grid: Vector2i = GridManager.world_to_grid(mouse_pos)
	
	if GridManager.is_valid_grid_pos(mouse_grid):
		var target_world: Vector2 = GridManager.grid_to_world(mouse_grid)
		draw_line(avatar.global_position, target_world, Color(1, 1, 0, 0.3), 2.0)
		
		# Círculo en tile destino
		draw_circle(target_world, 10, Color(1, 1, 0, 0.5))

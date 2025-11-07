extends Node

"""
InputManager - Sistema Central de Input
Role: ASISTENTE 1 - Input System
Version: 1.0

Maneja input unificado para PC y Mobile:
- Teclado (WASD, Flechas)
- Mouse (clicks)
- Touch (mobile)
- Joystick virtual (mobile)

DEPENDENCIES:
- Ninguna (sistema base)

SIGNALS:
- movement_input(direction: Vector2i)
- tile_selected(grid_pos: Vector2i)
- avatar_clicked(world_pos: Vector2)
- action_pressed(action_name: String)

PUBLIC API:
- get_input_method() -> InputMethod
- is_mobile() -> bool
- enable_mobile_controls()
- disable_mobile_controls()
"""

# ========================================
# ENUMS
# ========================================
enum InputMethod {
	KEYBOARD,   ## WASD / Flechas
	MOUSE,      ## Click y drag
	TOUCH,      ## Touch directo (mobile)
	GAMEPAD     ## Controlador (futuro)
}

# ========================================
# SEÑALES
# ========================================
signal movement_input(direction: Vector2i)
signal tile_selected(grid_pos: Vector2i)
signal avatar_clicked(world_pos: Vector2)
signal action_pressed(action_name: String)

# ========================================
# ESTADO
# ========================================
var current_input_method: InputMethod = InputMethod.KEYBOARD
var is_mobile_platform: bool = false
var mobile_controls: Node = null

# ========================================
# CONFIGURACIÓN
# ========================================
@export var enable_debug_prints: bool = false

# ========================================
# LIFECYCLE
# ========================================
func _ready() -> void:
	# Detectar plataforma
	_detect_platform()
	
	# Configurar controles móviles si es necesario
	if is_mobile_platform:
		_setup_mobile_controls()
	
	print("[InputManager] ✓ Inicializado")
	print("  Plataforma: %s" % ("Mobile" if is_mobile_platform else "PC"))
	print("  Input method: %s" % InputMethod.keys()[current_input_method])





func _detect_platform() -> void:
	"""Detecta si estamos en mobile o PC"""
	# TEMPORAL: Forzar mobile para testing
	is_mobile_platform = true  # ← Descomenta esta línea
	
	# Detección normal (comentar para testing)
	# is_mobile_platform = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	
	print("[InputManager] Platform: %s" % ("Mobile" if is_mobile_platform else "PC"))
	
	# Override para testing en PC (simular mobile)
	if OS.is_debug_build() and Input.is_key_pressed(KEY_F12):
		is_mobile_platform = true
		print("[InputManager] F12 detectado: Forzando modo mobile")

func _setup_mobile_controls() -> void:
	"""Carga e inicializa controles móviles"""
	var mobile_scene_path: String = "res://GameModules/UI/mobile_controls.tscn"
	
	if not ResourceLoader.exists(mobile_scene_path):
		push_warning("[InputManager] No se encontró mobile_controls.tscn")
		return
	
	var mobile_scene: PackedScene = load(mobile_scene_path)
	mobile_controls = mobile_scene.instantiate()
	add_child(mobile_controls)
	
	# Conectar señales del joystick
	if mobile_controls.has_signal("joystick_moved"):
		mobile_controls.joystick_moved.connect(_on_joystick_moved)
	if mobile_controls.has_signal("joystick_released"):
		mobile_controls.joystick_released.connect(_on_joystick_released)
	
	print("[InputManager] Controles móviles activados")

# ========================================
# INPUT HANDLING
# ========================================
func _input(event: InputEvent) -> void:
	# Teclado: WASD / Flechas
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_keyboard_input(event)
	
	# Mouse: Clicks
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_input(event)
	
	# Touch: Mobile (alternativa a mouse)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_touch_input(event)

func _handle_keyboard_input(event: InputEventKey) -> void:
	"""Maneja input de teclado"""
	var direction: Vector2i = Vector2i.ZERO
	
	match event.keycode:
		KEY_W, KEY_UP:
			direction = Vector2i(0, -1)
		KEY_S, KEY_DOWN:
			direction = Vector2i(0, 1)
		KEY_A, KEY_LEFT:
			direction = Vector2i(-1, 0)
		KEY_D, KEY_RIGHT:
			direction = Vector2i(1, 0)
		
		# Acciones especiales
		KEY_SPACE:
			action_pressed.emit("action_primary")
			return
		KEY_TAB:
			action_pressed.emit("cycle_avatar")
			return
		KEY_SHIFT:
			action_pressed.emit("toggle_control_mode")
			return
	
	if direction != Vector2i.ZERO:
		current_input_method = InputMethod.KEYBOARD
		movement_input.emit(direction)
		
		if enable_debug_prints:
			print("[InputManager] Keyboard: %s" % direction)

func _handle_mouse_input(event: InputEventMouseButton) -> void:
	"""Maneja clicks de mouse"""
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	current_input_method = InputMethod.MOUSE
	
	var click_pos: Vector2 = event.position
	var grid_pos: Vector2i = GridManager.world_to_grid(click_pos)
	
	# Verificar si clickeó en el grid
	if GridManager.is_valid_grid_pos(grid_pos):
		tile_selected.emit(grid_pos)
		
		if enable_debug_prints:
			print("[InputManager] Tile selected: %s" % grid_pos)
	else:
		# Click fuera del grid (puede ser en avatar u otro objeto)
		avatar_clicked.emit(click_pos)
		
		if enable_debug_prints:
			print("[InputManager] Click outside grid: %s" % click_pos)

func _handle_touch_input(event: InputEventScreenTouch) -> void:
	"""Maneja touch directo en mobile (similar a mouse)"""
	current_input_method = InputMethod.TOUCH
	
	var touch_pos: Vector2 = event.position
	var grid_pos: Vector2i = GridManager.world_to_grid(touch_pos)
	
	if GridManager.is_valid_grid_pos(grid_pos):
		tile_selected.emit(grid_pos)
		
		if enable_debug_prints:
			print("[InputManager] Touch tile: %s" % grid_pos)

# ========================================
# JOYSTICK MOBILE
# ========================================
func _on_joystick_moved(direction: Vector2) -> void:
	"""Callback del joystick virtual"""
	current_input_method = InputMethod.TOUCH
	
	# Convertir dirección analógica a digital (4 direcciones)
	var grid_direction: Vector2i = _analog_to_grid_direction(direction)
	
	if grid_direction != Vector2i.ZERO:
		movement_input.emit(grid_direction)
		
		if enable_debug_prints:
			print("[InputManager] Joystick: %s" % grid_direction)

func _on_joystick_released() -> void:
	"""Callback cuando se suelta el joystick"""
	if enable_debug_prints:
		print("[InputManager] Joystick released")

func _analog_to_grid_direction(analog: Vector2) -> Vector2i:
	"""
	Convierte dirección analógica del joystick a grid (4 direcciones)
	Args:
		analog: Vector2 normalizado del joystick (-1 a 1)
	Returns:
		Vector2i con dirección cardinal más cercana
	"""
	# Deadzone para evitar inputs accidentales
	const DEADZONE: float = 0.3
	
	if analog.length() < DEADZONE:
		return Vector2i.ZERO
	
	# Priorizar eje más fuerte (solo movimiento cardinal)
	if abs(analog.x) > abs(analog.y):
		# Movimiento horizontal
		return Vector2i(1 if analog.x > 0 else -1, 0)
	else:
		# Movimiento vertical
		return Vector2i(0, 1 if analog.y > 0 else -1)

# ========================================
# API PÚBLICA
# ========================================
func get_input_method() -> InputMethod:
	"""Obtiene el método de input actual"""
	return current_input_method

func is_mobile() -> bool:
	"""Verifica si estamos en plataforma móvil"""
	return is_mobile_platform

func enable_mobile_controls() -> void:
	"""Activa controles móviles manualmente"""
	if mobile_controls:
		mobile_controls.visible = true

func disable_mobile_controls() -> void:
	"""Desactiva controles móviles manualmente"""
	if mobile_controls:
		mobile_controls.visible = false

func toggle_debug_prints(enabled: bool) -> void:
	"""Activa/desactiva prints de debugging"""
	enable_debug_prints = enabled

# ========================================
# UTILIDADES
# ========================================
func get_movement_vector() -> Vector2:
	"""
	Obtiene vector de movimiento continuo (útil para otros sistemas)
	Returns:
		Vector2 con dirección WASD normalizada
	"""
	var movement: Vector2 = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1
	
	return movement.normalized()

# ========================================
# DEBUG
# ========================================
func print_input_state() -> void:
	"""Imprime estado actual del input (debugging)"""
	print("=== INPUT MANAGER STATE ===")
	print("  Platform: %s" % ("Mobile" if is_mobile_platform else "PC"))
	print("  Current method: %s" % InputMethod.keys()[current_input_method])
	print("  Mobile controls: %s" % ("Active" if mobile_controls else "Inactive"))
	print("  Debug prints: %s" % ("ON" if enable_debug_prints else "OFF"))
	print("===========================")

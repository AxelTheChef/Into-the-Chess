extends CanvasLayer

"""
MobileControls - Joystick Virtual para Mobile
Role: ASISTENTE 1 - Mobile Input
Version: 1.0

Joystick virtual en pantalla para dispositivos móviles

SIGNALS:
- joystick_moved(direction: Vector2)
- joystick_released()
"""

# ========================================
# SEÑALES
# ========================================
signal joystick_moved(direction: Vector2)
signal joystick_released()

# ========================================
# REFERENCIAS
# ========================================
@onready var joystick_base: Control = $JoystickBase
@onready var joystick_handle: Control = $JoystickBase/JoystickHandle

# ========================================
# CONFIGURACIÓN
# ========================================
@export var max_distance: float = 50.0      ## Radio máximo del joystick
@export var deadzone: float = 0.2           ## Zona muerta (0-1)
@export var return_speed: float = 20.0     ## Velocidad de retorno al centro

# ========================================
# ESTADO
# ========================================
var is_pressed: bool = false
var touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var current_direction: Vector2 = Vector2.ZERO

# ========================================
# LIFECYCLE
# ========================================
func _ready() -> void:
	# Calcular centro del joystick
	_update_joystick_center()
	
	# Configurar visibilidad inicial
	visible = OS.has_feature("mobile")
	
	print("[MobileControls] Joystick inicializado")

func _update_joystick_center() -> void:
	"""Calcula posición central del joystick"""
	joystick_center = joystick_base.global_position + joystick_base.size / 2

# ========================================
# INPUT
# ========================================
func _input(event: InputEvent) -> void:
	# Touch comenzó (mobile)
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_started(event.position, event.index)
		else:
			_on_touch_released(event.index)
	
	# Touch se mueve (drag mobile)
	elif event is InputEventScreenDrag:
		if is_pressed and event.index == touch_index:
			_on_touch_moved(event.position)
	
	# AÑADIR: Mouse para testing en PC
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_touch_started(event.position, 0)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_touch_released(0)
	
	# AÑADIR: Mouse drag para testing en PC
	elif event is InputEventMouseMotion:
		if is_pressed:
			_on_touch_moved(event.position)

func _on_touch_started(pos: Vector2, index: int) -> void:
	"""Callback cuando se toca la pantalla"""
	# Solo activar si toca dentro del área del joystick
	var distance_to_center: float = pos.distance_to(joystick_center)
	
	# Radio de activación (más grande que el visual)
	const ACTIVATION_RADIUS: float = 100.0
	
	if distance_to_center < ACTIVATION_RADIUS and not is_pressed:
		is_pressed = true
		touch_index = index
		
		# Opcional: Mover el joystick base al punto de toque
		# joystick_base.global_position = pos - joystick_base.size / 2
		# _update_joystick_center()

func _on_touch_moved(pos: Vector2) -> void:
	"""Callback cuando se arrastra el touch"""
	# Calcular dirección desde centro
	var direction: Vector2 = pos - joystick_center
	var distance: float = direction.length()
	
	# Limitar a max_distance
	if distance > max_distance:
		direction = direction.normalized() * max_distance
		distance = max_distance
	
	# Actualizar posición del handle visualmente
	joystick_handle.position = joystick_base.size / 2 + direction
	
	# Calcular dirección normalizada (0-1)
	var normalized_direction: Vector2 = direction / max_distance
	
	# Aplicar deadzone
	if normalized_direction.length() < deadzone:
		normalized_direction = Vector2.ZERO
	
	# Emitir señal solo si cambió
	if normalized_direction != current_direction:
		current_direction = normalized_direction
		joystick_moved.emit(normalized_direction)

func _on_touch_released(index: int) -> void:
	"""Callback cuando se suelta el touch"""
	if index == touch_index:
		is_pressed = false
		touch_index = -1
		current_direction = Vector2.ZERO
		
		# Emitir señal de release
		joystick_released.emit()

# ========================================
# ANIMACIÓN DE RETORNO
# ========================================
func _process(delta: float) -> void:
	# Retornar handle al centro cuando no está presionado
	if not is_pressed:
		var center_offset: Vector2 = joystick_base.size / 2
		var current_offset: Vector2 = joystick_handle.position
		
		# Lerp hacia el centro
		joystick_handle.position = current_offset.lerp(center_offset, return_speed * delta)

# ========================================
# API PÚBLICA
# ========================================
func get_joystick_direction() -> Vector2:
	"""Obtiene dirección actual del joystick (0-1)"""
	return current_direction

func reset_joystick() -> void:
	"""Resetea el joystick al centro"""
	is_pressed = false
	touch_index = -1
	current_direction = Vector2.ZERO
	joystick_handle.position = joystick_base.size / 2

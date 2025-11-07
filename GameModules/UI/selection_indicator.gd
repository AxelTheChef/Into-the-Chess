extends Sprite2D

"""
SelectionIndicator - Indicador visual sobre avatar seleccionado
Role: ASISTENTE 1 - Avatar System
Version: 1.0

Características:
- Anillo amarillo que rota
- Pulso suave de escala
- Se activa/desactiva automáticamente
"""

# ========================================
# CONFIGURACIÓN
# ========================================
@export var rotation_speed: float = 2.0    ## Radianes por segundo
@export var pulse_speed: float = 3.0       ## Ciclos por segundo
@export var pulse_intensity: float = 0.1   ## Amplitud del pulso (0-1)

var base_scale: Vector2 = Vector2(1.5, 1.5)

# ========================================
# LIFECYCLE
# ========================================
func _ready() -> void:
	# Crear textura del anillo
	_create_ring_texture()
	
	# Configurar propiedades
	z_index = -1  # Debajo del avatar
	visible = false

func _create_ring_texture() -> void:
	"""Crea textura de anillo circular"""
	var size: int = 64
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	var center: Vector2 = Vector2(size / 2.0, size / 2.0)
	var outer_radius: float = 28.0
	var inner_radius: float = 24.0
	
	# Dibujar anillo píxel por píxel
	for x in range(size):
		for y in range(size):
			var pixel_pos: Vector2 = Vector2(x, y)
			var dist: float = pixel_pos.distance_to(center)
			
			# Si está dentro del anillo
			if dist > inner_radius and dist < outer_radius:
				# Color amarillo con alpha suave en bordes
				var alpha: float = 1.0
				
				# Fade en borde exterior
				if dist > outer_radius - 2:
					alpha = (outer_radius - dist) / 2.0
				
				# Fade en borde interior
				if dist < inner_radius + 2:
					alpha = (dist - inner_radius) / 2.0
				
				img.set_pixel(x, y, Color(1, 1, 0, alpha * 0.8))
	
	texture = ImageTexture.create_from_image(img)
	print("[SelectionIndicator] Anillo creado")

# ========================================
# ANIMACIÓN
# ========================================
func _process(delta: float) -> void:
	if not visible:
		return
	
	# Rotar suavemente
	rotation += rotation_speed * delta
	
	# Pulso de escala
	var time: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 1.0 + sin(time * pulse_speed * TAU) * pulse_intensity
	scale = base_scale * pulse

# ========================================
# API PÚBLICA
# ========================================
func show_indicator() -> void:
	"""Muestra el indicador"""
	visible = true

func hide_indicator() -> void:
	"""Oculta el indicador"""
	visible = false

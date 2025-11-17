extends AvatarBase

"""
AvatarCochinilla - Avatar inicial del jugador
Role: ASISTENTE 1 - Avatar System
Version: 1.0

Características:
- 4 brazos para equipar plantas
- Velocidad media (200 px/s)
- Habilidad especial: Ball Mode (futura)

Stats base:
- HP: 70 (Asistente 2)
- Arms: 4
- Speed: 200
"""

# ========================================
# CONFIGURACIÓN ESPECÍFICA
# ========================================
func _ready() -> void:
	# Configurar propiedades específicas
	avatar_name = "Queen"
	arms_count = 4
	move_speed = 200.0
	
	# Configurar sprite
	_setup_sprite()
	
	# Llamar _ready del padre
	super._ready()
	
	print("[Reina] Avatar listo con %d brazos" % arms_count)

func _setup_sprite() -> void:
	"""Configura el sprite de Queen"""
	if not sprite:
		return
	
	# Intentar cargar sprite real
	var sprite_path: String = "res://Assets/Sprites/avatares-spr/horne.png"
	
	
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		print("[Reina] Sprite cargado: %s" % sprite_path)
	else:
		# Crear placeholder si no existe sprite
		_create_placeholder_sprite()

func _create_placeholder_sprite() -> void:
	"""Crea un placeholder visual (cuadrado marrón)"""
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Fondo marrón (color de cochinilla)
	img.fill(Color(0.36, 0.25, 0.2, 1.0))  # #5C4033
	
	# Añadir borde más oscuro
	for x in range(32):
		img.set_pixel(x, 0, Color(0.2, 0.15, 0.1, 1.0))   # Top
		img.set_pixel(x, 31, Color(0.2, 0.15, 0.1, 1.0))  # Bottom
	
	for y in range(32):
		img.set_pixel(0, y, Color(0.2, 0.15, 0.1, 1.0))   # Left
		img.set_pixel(31, y, Color(0.2, 0.15, 0.1, 1.0))  # Right
	
	# Añadir "ojos" simples (2 puntos blancos)
	img.set_pixel(10, 10, Color.WHITE)
	img.set_pixel(11, 10, Color.WHITE)
	img.set_pixel(20, 10, Color.WHITE)
	img.set_pixel(21, 10, Color.WHITE)
	
	sprite.texture = ImageTexture.create_from_image(img)
	print("[Reina] Placeholder creado")

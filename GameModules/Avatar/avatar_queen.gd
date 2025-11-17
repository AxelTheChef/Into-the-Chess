extends AvatarBase

"""
AvatarQueen - Avatar inicial del jugador (Reina de ajedrez)
Role: ASISTENTE 1 - Avatar System
Version: 1.1 (Vmin - Día 3-4)

ACTUALIZADO:
- Kochi/Cochinilla → Queen
- 4 brazos → 2 equipment slots
- Color marrón → Color morado (tema reina)
- Eliminada habilidad Ball Mode (no aplicable)

Características:
- 2 equipment slots para equipar piezas
- Velocidad media (200 px/s)
- Movimiento libre en grid 14x5

Stats base (Vmin):
- HP: 50 (será implementado por Asistente 2)
- Equipment Slots: 2
- Speed: 200.0
"""

# ========================================
# CONFIGURACIÓN ESPECÍFICA
# ========================================
func _ready() -> void:
	# Configurar propiedades específicas
	avatar_name = "Queen"
	equipment_slots = 2
	move_speed = 200.0
	
	# Configurar sprite
	_setup_sprite()
	
	# Llamar _ready del padre
	super._ready()
	
	print("[Queen] Avatar listo con %d equipment slots" % equipment_slots)

func _setup_sprite() -> void:
	"""Configura el sprite de Queen"""
	if not sprite:
		return
	
	# Intentar cargar sprite real
	var sprite_path: String = "res://Assets/Sprites/avatares-spr/horne.png"
	
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		print("[Queen] Sprite cargado: %s" % sprite_path)
	else:
		# Crear placeholder si no existe sprite
		_create_placeholder_sprite()

func _create_placeholder_sprite() -> void:
	"""Crea un placeholder visual (cuadrado morado con símbolo ♕)"""
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Fondo morado (color de realeza)
	img.fill(Color(0.5, 0.2, 0.7, 1.0))  # #8033B3 (morado)
	
	# Añadir borde más oscuro
	var border_color := Color(0.3, 0.1, 0.5, 1.0)  # Morado oscuro
	for x in range(32):
		img.set_pixel(x, 0, border_color)   # Top
		img.set_pixel(x, 31, border_color)  # Bottom
	
	for y in range(32):
		img.set_pixel(0, y, border_color)   # Left
		img.set_pixel(31, y, border_color)  # Right
	
	# Añadir "corona" simple (línea dorada en la parte superior)
	var crown_color := Color(1.0, 0.84, 0.0, 1.0)  # Dorado
	for x in range(8, 24):
		img.set_pixel(x, 8, crown_color)
		img.set_pixel(x, 9, crown_color)
	
	# Añadir puntos dorados (joyas de la corona)
	img.set_pixel(10, 6, crown_color)
	img.set_pixel(16, 6, crown_color)
	img.set_pixel(22, 6, crown_color)
	
	sprite.texture = ImageTexture.create_from_image(img)
	print("[Queen] Placeholder morado creado (♕)")

# ========================================
# EQUIPAMIENTO (Futuro - Asistente 3)
# ========================================
func equip_piece(_piece: Node, _slot: int) -> bool:
	"""
	Equipa una pieza en un slot.
	TODO: Implementar en Semana 2 con Asistente 3
	
	Args:
		_piece: Pieza a equipar (prefijo _ = parámetro no usado aún)
		_slot: Slot donde equipar (0-1 para Queen)
	
	Returns:
		true si se equipó exitosamente
	"""
	if _slot < 0 or _slot >= equipment_slots:
		print("[Queen] Slot inválido: %d (max: %d)" % [_slot, equipment_slots - 1])
		return false
	
	print("[Queen] Equipar pieza en slot %d (no implementado)" % _slot)
	return false

func unequip_piece(_slot: int) -> Node:
	"""
	Desequipa una pieza de un slot.
	TODO: Implementar en Semana 2 con Asistente 3
	
	Args:
		_slot: Slot del que desequipar (0-1) (prefijo _ = parámetro no usado aún)
	
	Returns:
		Pieza desequipada (o null)
	"""
	if _slot < 0 or _slot >= equipment_slots:
		print("[Queen] Slot inválido: %d" % _slot)
		return null
	
	print("[Queen] Desequipar slot %d (no implementado)" % _slot)
	return null

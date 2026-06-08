extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MUNDO 3 — MAPA DE SECCIONES (PLANETA HONGOS)
# ═══════════════════════════════════════════════════════════════

# Secciones del Mundo 3 (IDs 11-15 para no chocar con Mundos 1 y 2)
const SECCIONES : Array = [
	{ "id": 11, "nombre": "Tabla del 3",         "tipo": "mult",       "tabla": 3 },
	{ "id": 12, "nombre": "Tabla del 4",         "tipo": "mult",       "tabla": 4 },
	{ "id": 13, "nombre": "Tabla del 5",         "tipo": "mult",       "tabla": 5 },
	{ "id": 14, "nombre": "Multi mixtas 3-5",    "tipo": "mult_mixto", "max": 5  },
	{ "id": 15, "nombre": "Multi mixtas 3-7",    "tipo": "mult_mixto", "max": 7  },
]

const RUTA_SAVE : String = "user://mati_save.json"

var guardado_node
var indicador_estrella  : TextureRect = null
var indicador_wrap_node : Control     = null
var indicador_label0    : Label       = null

func _ready() -> void:
	guardado_node = load("res://scripts/guardado.gd").new()

	$LabelMonedas.visible = false
	_crear_indicador_estrella(self, Vector2(10.0, 10.0))
	_actualizar_label_monedas()
	_configurar_botones()

	$BtnVolver.pressed.connect(_volver_al_mundo)

# ─────────────────────────────────────────────────────────────
#  CONFIGURAR BOTONES
# ─────────────────────────────────────────────────────────────
func _configurar_botones() -> void:
	for i in range(SECCIONES.size()):
		var seccion = SECCIONES[i]
		var id_seccion = seccion["id"]
		var btn_index = i + 1
		var btn = get_node("ContenedorBotones/BtnSeccion" + str(btn_index))

		var desbloqueada = _seccion_desbloqueada_mundo3(id_seccion)
		var completada   = guardado_node.seccion_completada(id_seccion)
		var perfecta     = guardado_node.seccion_perfecta(id_seccion)

		var texto = "Sección " + str(btn_index) + " — " + seccion["nombre"]

		if not desbloqueada:
			texto = "🔒 " + texto
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.6)
		elif perfecta:
			texto = "⭐ " + texto + " ✓"
			btn.disabled = false
			btn.modulate = Color(1, 0.85, 0.3)
		elif completada:
			texto = "✓ " + texto
			btn.disabled = false
			btn.modulate = Color(0.6, 1, 0.6)
		else:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)

		btn.text = texto

		if btn.pressed.is_connected(_on_seccion_seleccionada):
			btn.pressed.disconnect(_on_seccion_seleccionada)
		btn.pressed.connect(_on_seccion_seleccionada.bind(id_seccion))

# ─────────────────────────────────────────────────────────────
#  DESBLOQUEO MUNDO 3 (la primera siempre disponible)
# ─────────────────────────────────────────────────────────────
func _seccion_desbloqueada_mundo3(id_seccion: int) -> bool:
	if id_seccion <= 11:
		return true
	return guardado_node.seccion_completada(id_seccion - 1)

# ─────────────────────────────────────────────────────────────
#  AL SELECCIONAR UNA SECCIÓN
# ─────────────────────────────────────────────────────────────
func _on_seccion_seleccionada(id_seccion: int) -> void:
	var datos = guardado_node.cargar()
	datos["seccion_actual"] = id_seccion

	var archivo = FileAccess.open(RUTA_SAVE, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

	TransitionManager.cambiar_escena("res://scenes/Mundo3Operaciones.tscn")

# ─────────────────────────────────────────────────────────────
#  INDICADOR DE ESTRELLAS
# ─────────────────────────────────────────────────────────────
func _actualizar_label_monedas() -> void:
	var datos   = guardado_node.cargar()
	var monedas = int(datos.get("monedas", 0))
	_actualizar_indicador_estrella(monedas)

func _crear_indicador_estrella(parent: Node, pos: Vector2) -> void:
	indicador_wrap_node = Control.new()
	parent.add_child(indicador_wrap_node)
	indicador_wrap_node.layout_mode   = 0
	indicador_wrap_node.position      = pos
	indicador_wrap_node.size          = Vector2(90.0, 90.0)
	indicador_wrap_node.clip_contents = true
	indicador_estrella = TextureRect.new()
	indicador_wrap_node.add_child(indicador_estrella)
	indicador_estrella.layout_mode  = 0
	indicador_estrella.position     = Vector2(0, 0)
	indicador_estrella.size         = Vector2(90.0, 90.0)
	indicador_estrella.stretch_mode = TextureRect.STRETCH_SCALE
	indicador_estrella.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	indicador_label0 = Label.new()
	indicador_wrap_node.add_child(indicador_label0)
	indicador_label0.layout_mode          = 0
	indicador_label0.position             = Vector2(0, 0)
	indicador_label0.size                 = Vector2(90.0, 90.0)
	indicador_label0.text                 = "⭐ 0"
	indicador_label0.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicador_label0.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	indicador_label0.add_theme_font_size_override("font_size", 24)
	indicador_label0.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	indicador_label0.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	indicador_label0.add_theme_constant_override("shadow_offset_x", 2)
	indicador_label0.add_theme_constant_override("shadow_offset_y", 2)
	indicador_label0.visible = false

func _actualizar_indicador_estrella(n: int) -> void:
	if indicador_estrella == null:
		return
	indicador_wrap_node.visible = true
	if n <= 0:
		indicador_estrella.visible = false
		if indicador_label0:
			indicador_label0.visible = true
		return
	if indicador_label0:
		indicador_label0.visible = false
	indicador_estrella.visible = true
	var c    : int    = clampi(n, 1, 100)
	var ruta : String = "res://assets/ui/indicador_estrellas/%d.png" % c
	if ResourceLoader.exists(ruta):
		indicador_estrella.texture = load(ruta)
	else:
		indicador_wrap_node.visible = false

# ─────────────────────────────────────────────────────────────
#  VOLVER AL MUNDO 3
# ─────────────────────────────────────────────────────────────
func _volver_al_mundo() -> void:
	TransitionManager.cambiar_escena("res://scenes/Mundo3Explorar.tscn")

extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MUNDO 1 — MAPA DE SECCIONES
# ═══════════════════════════════════════════════════════════════

const SECCIONES : Array = [
	{ "id": 1, "nombre": "Sumas hasta 10",       "tipo": "suma",  "max": 10 },
	{ "id": 2, "nombre": "Sumas hasta 20",       "tipo": "suma",  "max": 20 },
	{ "id": 3, "nombre": "Sumas hasta 30",       "tipo": "suma",  "max": 30 },
	{ "id": 4, "nombre": "Restas hasta 20",      "tipo": "resta", "max": 20 },
	{ "id": 5, "nombre": "Mixto +/- hasta 30",   "tipo": "mixto", "max": 30 },
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
	for seccion in SECCIONES:
		var id_seccion = seccion["id"]
		var btn = get_node("ContenedorBotones/BtnSeccion" + str(id_seccion))

		var desbloqueada = guardado_node.seccion_desbloqueada(id_seccion)
		var completada   = guardado_node.seccion_completada(id_seccion)
		var perfecta     = guardado_node.seccion_perfecta(id_seccion)

		var texto = "Sección " + str(id_seccion) + " — " + seccion["nombre"]

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
#  AL SELECCIONAR UNA SECCIÓN  (CORREGIDO)
# ─────────────────────────────────────────────────────────────
func _on_seccion_seleccionada(id_seccion: int) -> void:
	print("[DEBUG] Sección elegida en el mapa: ", id_seccion)

	# Guardar seccion_actual DIRECTO al archivo JSON
	# (sin usar guardar() porque no maneja ese campo)
	var datos = guardado_node.cargar()
	datos["seccion_actual"] = id_seccion

	var archivo = FileAccess.open(RUTA_SAVE, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()
		print("[DEBUG] Guardado seccion_actual = ", id_seccion)

	get_tree().change_scene_to_file("res://scenes/Mundo1Operaciones.tscn")

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
#  VOLVER AL MUNDO 1
# ─────────────────────────────────────────────────────────────
func _volver_al_mundo() -> void:
	get_tree().change_scene_to_file("res://scenes/Mundo1Explorar.tscn")

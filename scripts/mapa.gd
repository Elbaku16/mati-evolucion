extends Control

# ═══════════════════════════════════════════════════════════════
#  MAPA — Selección de mundo
#  Detecta clics por posición en lugar de usar el área del botón
# ═══════════════════════════════════════════════════════════════

const SKINS_TEXTURA_MAPA = {
	"default":  "res://assets/personajes/mati_mapa.PNG",
	"fachero":  "res://assets/personajes/mati_fachero.PNG",
	"ninja":    "res://assets/personajes/mati_ninja.PNG",
	"escolar":  "res://assets/personajes/mati_escolar.PNG",
}

const OFFSET_MATI_NIVEL = {
	1: Vector2(155, 195),
	2: Vector2(575, 335),
	3: Vector2(975, 195),
}

# Centros aproximados de cada planeta y radio de detección de clic
# Si los planetas están en otra posición, ajusta estos valores
const PLANETAS = {
	1: { "centro": Vector2(220, 480), "radio": 180 },   # Planeta verde (Mundo 1)
	2: { "centro": Vector2(640, 560), "radio": 180 },   # Planeta hielo (Mundo 2)
	3: { "centro": Vector2(1080, 460), "radio": 180 },  # Planeta morado (Mundo 3)
}

var guardado_node
var mundo1_completado   : bool        = false
var mundo2_completado   : bool        = false
var mundo3_completado   : bool        = false
var indicador_estrella  : TextureRect = null
var indicador_wrap_node : Control     = null
var indicador_label0    : Label       = null

func _ready() -> void:
	guardado_node = load("res://scripts/guardado.gd").new()
	var datos = guardado_node.cargar()

	mundo1_completado = datos.get("mundo1_completado", false)
	mundo2_completado = _todas_secciones_mundo2_completas()
	mundo3_completado = _todas_secciones_mundo3_completas()

	# Mati se posiciona en el mundo más avanzado desbloqueado
	var nivel_mati = 1
	if mundo2_completado:
		nivel_mati = 3
	elif mundo1_completado:
		nivel_mati = 2

	$MatiMapa.position = OFFSET_MATI_NIVEL.get(nivel_mati, OFFSET_MATI_NIVEL[1])

	# Aplicar skin activa al personaje del mapa
	var skin_id = datos.get("skin_activa", "default")
	var ruta_tex = SKINS_TEXTURA_MAPA.get(skin_id, SKINS_TEXTURA_MAPA["default"])
	var tex = load(ruta_tex)
	if tex:
		$MatiMapa.texture = tex

	# Indicador de estrellas (reemplaza al LabelMonedas)
	if has_node("LabelMonedas"):
		$LabelMonedas.visible = false
	_crear_indicador_estrella(self, Vector2(10.0, 8.0))
	var monedas_init : int = int(datos.get("monedas", 0))
	_actualizar_indicador_estrella(monedas_init)

	# Candados (visuales)
	_actualizar_candados()

	# Botón tienda
	if has_node("BtnTienda"):
		$BtnTienda.pressed.connect(_ir_a_tienda)
		_estilo_btn_tienda($BtnTienda)

	# Desactivar los botones porque ahora detectamos clics manualmente
	# (así no interfieren)
	if has_node("Planeta1"):
		$Planeta1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Planeta2"):
		$Planeta2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Planeta3"):
		$Planeta3.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Botón Historia (libro dorado)
	_crear_btn_historia()

	# Llaves de progreso
	_mostrar_llaves()

	# ══════════════════════════════════════════════════════════
	#  🚧 BOTÓN DEV — BORRAR ANTES DE PUBLICAR 🚧
	#  Desbloquea todos los mundos sin completar desafíos.
	# ══════════════════════════════════════════════════════════
	_crear_btn_dev()

# ─────────────────────────────────────────────────────────────
#  DETECCIÓN DE CLIC POR POSICIÓN
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clic_pos = event.position
		print("[MAPA] Clic en: ", clic_pos)

		for id_planeta in PLANETAS.keys():
			var planeta = PLANETAS[id_planeta]
			var distancia = clic_pos.distance_to(planeta["centro"])
			if distancia <= planeta["radio"]:
				_seleccionar_planeta(id_planeta)
				return

# ─────────────────────────────────────────────────────────────
#  SELECCIONAR PLANETA
# ─────────────────────────────────────────────────────────────
func _seleccionar_planeta(id_planeta: int) -> void:
	print("[MAPA] Planeta seleccionado: ", id_planeta)

	match id_planeta:
		1:
			TransitionManager.cambiar_escena("res://scenes/Mundo1Explorar.tscn")
		2:
			if mundo1_completado:
				TransitionManager.cambiar_escena("res://scenes/Mundo2Explorar.tscn")
		3:
			if mundo2_completado:
				TransitionManager.cambiar_escena("res://scenes/Mundo3Explorar.tscn")

# ─────────────────────────────────────────────────────────────
#  TODAS LAS SECCIONES MUNDO 2 (6-10)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_mundo2_completas() -> bool:
	for i in range(6, 11):
		if not guardado_node.seccion_completada(i):
			return false
	return true

# ─────────────────────────────────────────────────────────────
#  TODAS LAS SECCIONES MUNDO 3 (11-15)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_mundo3_completas() -> bool:
	for i in range(11, 15):
		if not guardado_node.seccion_completada(i):
			return false
	return true

# ─────────────────────────────────────────────────────────────
#  CANDADOS
# ─────────────────────────────────────────────────────────────
# ─────────────────────────────────────────────────────────────
#  INDICADOR DE ESTRELLAS (imagen 1-100 del diseñador)
# ─────────────────────────────────────────────────────────────
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

func _ir_a_tienda() -> void:
	TransitionManager.cambiar_escena("res://scenes/Tienda.tscn")

# ─────────────────────────────────────────────────────────────
#  BOTÓN HISTORIA — libro dorado que abre las ilustraciones
# ─────────────────────────────────────────────────────────────
func _crear_btn_historia() -> void:
	var btn := TextureButton.new()
	btn.layout_mode          = 0
	btn.ignore_texture_size  = true
	btn.stretch_mode         = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.position = Vector2(8.0, 8.0)
	btn.size     = Vector2(90.0, 90.0)

	var tex = load("res://assets/ui/boton_historia.png")
	if tex:
		btn.texture_normal  = tex
		btn.texture_pressed = tex   # misma imagen; el engine oscurece al presionar

	btn.pressed.connect(_ir_a_historia)
	add_child(btn)

# ─────────────────────────────────────────────────────────────
#  ESTILO BOTÓN TIENDA
# ─────────────────────────────────────────────────────────────
func _estilo_btn_tienda(btn: Button) -> void:
	# ── Tamaño y posición ────────────────────────────────────
	btn.position = Vector2(1000.0, 8.0)
	btn.size     = Vector2(265.0, 68.0)
	btn.text     = "🛒  Tienda"
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_shadow_color", Color(0.15, 0.04, 0.38, 0.90))
	btn.add_theme_constant_override("shadow_offset_x", 2)
	btn.add_theme_constant_override("shadow_offset_y", 3)

	var r : int = 34   # altura / 2 = píldora perfecta

	# ── Normal ───────────────────────────────────────────────
	var s_n := StyleBoxFlat.new()
	s_n.bg_color                   = Color(0.62, 0.28, 0.98)
	s_n.corner_radius_top_left     = r
	s_n.corner_radius_top_right    = r
	s_n.corner_radius_bottom_left  = r
	s_n.corner_radius_bottom_right = r
	s_n.border_width_left   = 4
	s_n.border_width_right  = 4
	s_n.border_width_top    = 4
	s_n.border_width_bottom = 4
	s_n.border_color        = Color(0.82, 0.62, 1.00)
	btn.add_theme_stylebox_override("normal", s_n)

	# ── Hover ────────────────────────────────────────────────
	var s_h := StyleBoxFlat.new()
	s_h.bg_color                   = Color(0.72, 0.38, 1.00)
	s_h.corner_radius_top_left     = r
	s_h.corner_radius_top_right    = r
	s_h.corner_radius_bottom_left  = r
	s_h.corner_radius_bottom_right = r
	s_h.border_width_left   = 4
	s_h.border_width_right  = 4
	s_h.border_width_top    = 4
	s_h.border_width_bottom = 4
	s_h.border_color        = Color(0.90, 0.72, 1.00)
	btn.add_theme_stylebox_override("hover", s_h)

	# ── Pressed ──────────────────────────────────────────────
	var s_p := StyleBoxFlat.new()
	s_p.bg_color                   = Color(0.42, 0.14, 0.78)
	s_p.corner_radius_top_left     = r
	s_p.corner_radius_top_right    = r
	s_p.corner_radius_bottom_left  = r
	s_p.corner_radius_bottom_right = r
	s_p.border_width_left   = 4
	s_p.border_width_right  = 4
	s_p.border_width_top    = 4
	s_p.border_width_bottom = 4
	s_p.border_color        = Color(0.72, 0.48, 1.00)
	btn.add_theme_stylebox_override("pressed", s_p)

	# ── Destellos blancos (efecto vidrio) — esquina superior derecha ─
	# Ovalito grande
	var g1 := Panel.new()
	btn.add_child(g1)
	g1.layout_mode  = 0
	g1.position     = Vector2(btn.size.x - 55.0, 8.0)
	g1.size         = Vector2(26.0, 14.0)
	g1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sg1 := StyleBoxFlat.new()
	sg1.bg_color                   = Color(1.0, 1.0, 1.0, 0.55)
	sg1.corner_radius_top_left     = 7
	sg1.corner_radius_top_right    = 7
	sg1.corner_radius_bottom_left  = 7
	sg1.corner_radius_bottom_right = 7
	g1.add_theme_stylebox_override("panel", sg1)

	# Ovalito pequeño
	var g2 := Panel.new()
	btn.add_child(g2)
	g2.layout_mode  = 0
	g2.position     = Vector2(btn.size.x - 24.0, 11.0)
	g2.size         = Vector2(14.0, 10.0)
	g2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sg2 := StyleBoxFlat.new()
	sg2.bg_color                   = Color(1.0, 1.0, 1.0, 0.38)
	sg2.corner_radius_top_left     = 5
	sg2.corner_radius_top_right    = 5
	sg2.corner_radius_bottom_left  = 5
	sg2.corner_radius_bottom_right = 5
	g2.add_theme_stylebox_override("panel", sg2)

# ══════════════════════════════════════════════════════════════
#  🚧 BOTÓN DEV — BORRAR ANTES DE PUBLICAR 🚧
# ══════════════════════════════════════════════════════════════
func _crear_btn_dev() -> void:
	var btn := Button.new()
	btn.text = "🔓 DEV"
	btn.position = Vector2(8.0, 660.0)   # esquina inferior izquierda
	btn.size     = Vector2(110.0, 50.0)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	# Fondo rojo para que sea obvio que es de prueba
	var st := StyleBoxFlat.new()
	st.bg_color                   = Color(0.75, 0.10, 0.10)
	st.corner_radius_top_left     = 10
	st.corner_radius_top_right    = 10
	st.corner_radius_bottom_left  = 10
	st.corner_radius_bottom_right = 10
	st.border_width_left   = 2
	st.border_width_right  = 2
	st.border_width_top    = 2
	st.border_width_bottom = 2
	st.border_color = Color(1.0, 0.45, 0.45)
	btn.add_theme_stylebox_override("normal",  st)
	btn.add_theme_stylebox_override("hover",   st)
	btn.add_theme_stylebox_override("pressed", st)
	btn.pressed.connect(_desbloquear_todo_dev)
	add_child(btn)

func _desbloquear_todo_dev() -> void:
	var datos = guardado_node.cargar()
	# Solo desbloquear acceso a los mundos — NO marcar secciones completadas
	# (así los NPCs siguen luciendo normales y a full brillo para testear)
	datos["mundo1_completado"] = true
	var archivo = FileAccess.open("user://mati_save.json", FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()
	# Refrescar estado local y candados
	mundo1_completado = true
	mundo2_completado = true
	_actualizar_candados()
	print("[DEV] Mundos desbloqueados ✓  (secciones sin tocar)")

func _ir_a_historia() -> void:
	TransitionManager.cambiar_escena("res://scenes/Historia.tscn")

# ─────────────────────────────────────────────────────────────
#  LLAVES DE PROGRESO — se muestran en la esquina inferior derecha
# ─────────────────────────────────────────────────────────────
func _mostrar_llaves() -> void:
	var llaves := [
		{ "ruta": "res://assets/ui/llaves/llave_mundo1.PNG", "ganada": mundo1_completado },
		{ "ruta": "res://assets/ui/llaves/llave_mundo2.PNG", "ganada": mundo2_completado },
		{ "ruta": "res://assets/ui/llaves/llave_mundo3.PNG", "ganada": mundo3_completado },
	]

	var size    : float = 148.0
	var gap     : float = 18.0
	var total_w : float = 3.0 * size + 2.0 * gap
	var start_x : float = (1280.0 - total_w) / 2.0   # centradas horizontalmente
	var y       : float = 720.0 - size - 12.0          # pegadas al borde inferior

	for i in range(llaves.size()):
		var info = llaves[i]
		var rect := TextureRect.new()
		rect.layout_mode  = 0
		rect.position     = Vector2(start_x + float(i) * (size + gap), y)
		rect.size         = Vector2(size, size)
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if ResourceLoader.exists(info["ruta"]):
			rect.texture = load(info["ruta"])

		if info["ganada"]:
			rect.modulate = Color(1.0, 1.0, 1.0, 1.0)   # color pleno
		else:
			rect.modulate = Color(0.25, 0.25, 0.25, 0.50) # grisado / bloqueada

		add_child(rect)

func _actualizar_candados() -> void:
	if has_node("CandadoPl2"):
		$CandadoPl2.visible = not mundo1_completado
	if has_node("CandadoPl3"):
		$CandadoPl3.visible = not mundo2_completado

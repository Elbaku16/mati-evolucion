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
	2: Vector2(575, 320),
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
var _musica_activa_mapa : bool        = true
var _btn_vol_mapa       : TextureButton = null
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

	# Botón Habilidades
	_crear_btn_habilidades()

	# Botón Misiones
	_crear_btn_misiones()

	# Llaves de progreso
	_mostrar_llaves()


	# Diploma — solo si los 3 mundos están completos
	if mundo1_completado and mundo2_completado and mundo3_completado:
		_crear_btn_diploma(datos.get("nombre", "Jugador"))

	# Botón de volumen — esquina inferior derecha
	_btn_vol_mapa = TextureButton.new()
	_btn_vol_mapa.ignore_texture_size = true
	_btn_vol_mapa.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var tex_vol_mapa := load("res://assets/ui/Botones Vector/volumen.png") as Texture2D
	if tex_vol_mapa:
		_btn_vol_mapa.texture_normal = tex_vol_mapa
	_btn_vol_mapa.layout_mode = 1
	_btn_vol_mapa.size = Vector2(50, 50)
	_btn_vol_mapa.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_vol_mapa.offset_left   = -66.0
	_btn_vol_mapa.offset_top    = -66.0
	_btn_vol_mapa.offset_right  = -16.0
	_btn_vol_mapa.offset_bottom = -16.0
	_btn_vol_mapa.pressed.connect(_on_vol_mapa_presionado)
	add_child(_btn_vol_mapa)

# ─────────────────────────────────────────────────────────────
#  DETECCIÓN DE CLIC POR POSICIÓN
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clic_pos = event.position
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
	match id_planeta:
		1:
			TransitionManager.cambiar_escena("res://scenes/Mundo1Explorar.tscn", "barrido")
		2:
			if mundo1_completado:
				TransitionManager.cambiar_escena("res://scenes/Mundo2Explorar.tscn", "barrido")
		3:
			if mundo2_completado:
				TransitionManager.cambiar_escena("res://scenes/Mundo3Explorar.tscn", "barrido")

# ─────────────────────────────────────────────────────────────
#  TODAS LAS SECCIONES MUNDO 2 (6-10)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_mundo2_completas() -> bool:
	for i in range(6, 11):
		if not guardado_node.seccion_completada(i):
			return false
	return true

# ─────────────────────────────────────────────────────────────
#  TODAS LAS SECCIONES MUNDO 3 (11-17)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_mundo3_completas() -> bool:
	for i in range(11, 18):
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
	indicador_wrap_node.size          = Vector2(120.0, 56.0)

	# Ícono estrella PNG (siempre visible)
	var ico := TextureRect.new()
	if ResourceLoader.exists("res://assets/ui/Estrella Amarilla.PNG"):
		ico.texture = load("res://assets/ui/Estrella Amarilla.PNG")
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ico.layout_mode  = 0
	ico.position     = Vector2(0, 4)
	ico.size         = Vector2(48, 48)
	ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
	indicador_wrap_node.add_child(ico)

	# Imagen numérica (n > 0)
	indicador_estrella = TextureRect.new()
	indicador_wrap_node.add_child(indicador_estrella)
	indicador_estrella.layout_mode  = 0
	indicador_estrella.position     = Vector2(52, 0)
	indicador_estrella.size         = Vector2(56.0, 56.0)
	indicador_estrella.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	indicador_estrella.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE

	# Etiqueta para 0
	indicador_label0 = Label.new()
	indicador_wrap_node.add_child(indicador_label0)
	indicador_label0.layout_mode          = 0
	indicador_label0.position             = Vector2(52, 8)
	indicador_label0.size                 = Vector2(56.0, 40.0)
	indicador_label0.text                 = "0"
	indicador_label0.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicador_label0.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	indicador_label0.add_theme_font_size_override("font_size", 26)
	indicador_label0.add_theme_color_override("font_color", Color(1.0, 0.92, 0.0))
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

func _on_vol_mapa_presionado() -> void:
	_musica_activa_mapa = not _musica_activa_mapa
	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").set_volumen(1.0 if _musica_activa_mapa else 0.0)
	if _btn_vol_mapa:
		_btn_vol_mapa.modulate = Color(1, 1, 1, 1) if _musica_activa_mapa else Color(0.5, 0.5, 0.5, 1)

func _ir_a_tienda() -> void:
	TransitionManager.cambiar_escena("res://scenes/Tienda.tscn")

func _ir_a_habilidades() -> void:
	TransitionManager.cambiar_escena("res://scenes/PanelHabilidades.tscn")

# ─────────────────────────────────────────────────────────────
#  BOTÓN HISTORIA — libro dorado que abre las ilustraciones
# ─────────────────────────────────────────────────────────────
func _crear_btn_historia() -> void:
	var btn := TextureButton.new()
	btn.layout_mode          = 0
	btn.ignore_texture_size  = true
	btn.stretch_mode         = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.position = Vector2(8.0, 105.0)
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
	btn.text     = "  Tienda"
	if ResourceLoader.exists("res://assets/ui/Carrito.png"):
		var icono := TextureRect.new()
		icono.texture = load("res://assets/ui/Carrito.png")
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icono.size = Vector2(40, 40)
		icono.position = Vector2(10, 14)
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icono)
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

func _crear_btn_diploma(nombre_jugador: String) -> void:
	var btn := Button.new()
	btn.text = "🎓  Ver Diploma"
	btn.add_theme_font_size_override("font_size", 20)
	btn.layout_mode = 1
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left   = -220.0
	btn.offset_top    =  16.0
	btn.offset_right  =  -16.0
	btn.offset_bottom =  60.0
	btn.modulate.a = 0.0
	btn.pressed.connect(func(): _mostrar_diploma(nombre_jugador))
	add_child(btn)
	var tw := create_tween()
	tw.tween_property(btn, "modulate:a", 1.0, 0.6).set_delay(0.5)

func _mostrar_diploma(nombre: String) -> void:
	var dip_script = load("res://scripts/diploma.gd")
	if dip_script:
		dip_script.mostrar(self, nombre)

func _crear_btn_misiones() -> void:
	var btn := Button.new()
	btn.text = "📋 Misiones"
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.position = Vector2(16, 80)
	btn.size     = Vector2(220, 56)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.08, 0.28, 0.55)
	sty.corner_radius_top_left = 14; sty.corner_radius_top_right = 14
	sty.corner_radius_bottom_left = 14; sty.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h := sty.duplicate()
	sty_h.bg_color = Color(0.12, 0.40, 0.75)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/PanelMisiones.tscn")
	)
	add_child(btn)

func _crear_btn_habilidades() -> void:
	var btn := Button.new()
	btn.text = "⚡ Habilidades"
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.position = Vector2(16, 16)
	btn.size     = Vector2(220, 56)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.28, 0.08, 0.60)
	sty.corner_radius_top_left = 14; sty.corner_radius_top_right = 14
	sty.corner_radius_bottom_left = 14; sty.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", sty)
	var sty_h := sty.duplicate()
	sty_h.bg_color = Color(0.40, 0.12, 0.80)
	btn.add_theme_stylebox_override("hover", sty_h)
	btn.pressed.connect(_ir_a_habilidades)
	add_child(btn)

func _actualizar_candados() -> void:
	if has_node("CandadoPl2"):
		$CandadoPl2.visible = not mundo1_completado
	if has_node("CandadoPl3"):
		$CandadoPl3.visible = not mundo2_completado

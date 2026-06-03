extends Control

# ═══════════════════════════════════════════════════════════════
#  TIENDA — Skins de Mati
#  Cards construidas con las imágenes del diseñador gráfico.
#  Cada skin tiene 3 estados: comprar / cambiar / equipado.
# ═══════════════════════════════════════════════════════════════

const SKINS_CONFIG : Dictionary = {
	"fachero": {
		"nombre":   "Mati fachero",
		"precio":   30,
		"comprar":  "res://assets/ui/tienda/fachero_comprar.png",
		"cambiar":  "res://assets/ui/tienda/fachero_cambiar.png",
		"equipado": "res://assets/ui/tienda/fachero_equipado.png",
	},
	"ninja": {
		"nombre":   "Mati ninja",
		"precio":   50,
		"comprar":  "res://assets/ui/tienda/ninja_comprar.png",
		"cambiar":  "res://assets/ui/tienda/ninja_cambiar.png",
		"equipado": "res://assets/ui/tienda/ninja_equipado.png",
	},
	"escolar": {
		"nombre":   "Mati escolar",
		"precio":   80,
		"comprar":  "res://assets/ui/tienda/escolar_comprar.png",
		"cambiar":  "res://assets/ui/tienda/escolar_cambiar.png",
		"equipado": "res://assets/ui/tienda/escolar_equipado.png",
	}
}

const SKIN_ORDER : Array = ["fachero", "ninja", "escolar"]

const SCR_W    : float = 1280.0
const SCR_H    : float = 720.0
const CARD_W   : float = 310.0
const CARD_H   : float = 388.0   # 310 × (2445/1954) ≈ 388
const CARD_GAP : float = 35.0
const CARD_Y   : float = 140.0

var guardado_node
var label_monedas       : Label      = null   # ya no se usa, conservado por compatibilidad
var indicador_estrella  : TextureRect = null
var indicador_wrap_node : Control     = null
var indicador_label0    : Label       = null
var botones_skins  : Dictionary = {}   # skin_id → Button (invisible, sobre el botón de la imagen)
var card_textures  : Dictionary = {}   # skin_id → TextureRect (la card completa)
var labels_error   : Dictionary = {}   # skin_id → Label "¡Faltan monedas!"

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	guardado_node = load("res://scripts/guardado.gd").new()
	_construir_ui()
	_actualizar_ui()

# ─────────────────────────────────────────────────────────────
#  CONSTRUIR UI
# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:

	# ── Fondo oscuro base ────────────────────────────────────
	var bg := ColorRect.new()
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.09, 0.04, 0.20)

	# ── Fondo galaxy ─────────────────────────────────────────
	var bg_tex := TextureRect.new()
	add_child(bg_tex)
	bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.texture      = load("res://assets/fondos/Fondo.png")

	# ── Barra título ──────────────────────────────────────────
	var bar_w : float = 820.0
	var bar_h : float = 72.0
	var bar_x : float = (SCR_W - bar_w) * 0.5
	var bar_y : float = 14.0

	# Sombra exterior del bar (anillo oscuro)
	var bar_sombra := Panel.new()
	add_child(bar_sombra)
	bar_sombra.layout_mode = 0
	bar_sombra.position    = Vector2(bar_x - 6, bar_y - 6)
	bar_sombra.size        = Vector2(bar_w + 12, bar_h + 12)
	_estilo_panel(bar_sombra, Color(0.22, 0.08, 0.55, 0.80), 46)

	# Borde brillante (anillo lavanda)
	var bar_borde := Panel.new()
	add_child(bar_borde)
	bar_borde.layout_mode = 0
	bar_borde.position    = Vector2(bar_x - 3, bar_y - 3)
	bar_borde.size        = Vector2(bar_w + 6, bar_h + 6)
	_estilo_panel(bar_borde, Color(0.62, 0.42, 1.00), 44)

	# Cuerpo del bar (azul-morado como el del diseñador)
	var bar_fondo := Panel.new()
	add_child(bar_fondo)
	bar_fondo.layout_mode = 0
	bar_fondo.position    = Vector2(bar_x, bar_y)
	bar_fondo.size        = Vector2(bar_w, bar_h)
	_estilo_panel(bar_fondo, Color(0.32, 0.20, 0.88), 42)

	# Brillo interno superior (efecto vidrio)
	var bar_glow := Panel.new()
	add_child(bar_glow)
	bar_glow.layout_mode = 0
	bar_glow.position    = Vector2(bar_x + 6, bar_y + 4)
	bar_glow.size        = Vector2(bar_w - 12, bar_h * 0.42)
	_estilo_panel(bar_glow, Color(0.75, 0.62, 1.00, 0.22), 38)

	var lbl_titulo := Label.new()
	add_child(lbl_titulo)
	lbl_titulo.layout_mode          = 0
	lbl_titulo.position             = Vector2(bar_x, bar_y)
	lbl_titulo.size                 = Vector2(bar_w, bar_h)
	lbl_titulo.text                 = "TIENDA"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 50)
	lbl_titulo.add_theme_color_override("font_color", Color.WHITE)
	lbl_titulo.add_theme_constant_override("outline_size", 4)
	lbl_titulo.add_theme_color_override("font_outline_color", Color(0.18, 0.06, 0.50))

	# ── Indicador de estrellas (imagen del diseñador) ────────────
	_crear_indicador_estrella(self, Vector2(10.0, 8.0))

	# ── Cards ─────────────────────────────────────────────────
	var total_w : float = CARD_W * 3.0 + CARD_GAP * 2.0
	var start_x : float = (SCR_W - total_w) * 0.5

	for i in range(SKIN_ORDER.size()):
		var skin_id : String = SKIN_ORDER[i]
		var cx      : float  = start_x + float(i) * (CARD_W + CARD_GAP)
		_crear_card(skin_id, SKINS_CONFIG[skin_id], Vector2(cx, CARD_Y))

	# ── Fila "Mati Original" debajo de las cards ─────────────
	_crear_strip_default()

	# ── Botón volver ─────────────────────────────────────────
	var btn_v := Button.new()
	add_child(btn_v)
	btn_v.layout_mode = 0
	btn_v.position    = Vector2(24.0, SCR_H - 72.0)
	btn_v.size        = Vector2(220.0, 52.0)
	btn_v.text        = "← Volver al mapa"
	btn_v.add_theme_font_size_override("font_size", 18)
	btn_v.add_theme_color_override("font_color", Color.WHITE)
	_estilo_boton(btn_v, Color(0.35, 0.16, 0.72), Color(0.52, 0.30, 0.94))
	btn_v.pressed.connect(_volver)

# ─────────────────────────────────────────────────────────────
#  FILA MATI ORIGINAL — siempre disponible, sin costo
# ─────────────────────────────────────────────────────────────
func _crear_strip_default() -> void:
	var total_w : float = CARD_W * 3.0 + CARD_GAP * 2.0
	var sx      : float = (SCR_W - total_w) * 0.5
	var sy      : float = CARD_Y + CARD_H + 16.0   # justo debajo de las cards

	var root := Control.new()
	add_child(root)
	root.layout_mode = 0
	root.position    = Vector2(sx, sy)
	root.size        = Vector2(total_w, 86.0)

	# Sombra
	var sombra := Panel.new()
	root.add_child(sombra)
	sombra.layout_mode = 0
	sombra.position    = Vector2(-4, -4)
	sombra.size        = Vector2(total_w + 8, 94.0)
	_estilo_panel(sombra, Color(0.18, 0.08, 0.50, 0.75), 24)

	# Cuerpo
	var panel := Panel.new()
	root.add_child(panel)
	panel.layout_mode = 0
	panel.position    = Vector2(0, 0)
	panel.size        = Vector2(total_w, 86.0)
	_estilo_panel(panel, Color(0.32, 0.20, 0.88, 0.90), 22)

	# Vista previa de Mati
	var img := TextureRect.new()
	root.add_child(img)
	img.layout_mode  = 0
	img.position     = Vector2(14, 5)
	img.size         = Vector2(68, 76)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	if ResourceLoader.exists("res://assets/personajes/mati_frente.PNG"):
		img.texture = load("res://assets/personajes/mati_frente.PNG")

	# Nombre
	var lbl_nom := Label.new()
	root.add_child(lbl_nom)
	lbl_nom.layout_mode = 0
	lbl_nom.position    = Vector2(96, 8)
	lbl_nom.size        = Vector2(400, 36)
	lbl_nom.text        = "Mati Original"
	lbl_nom.add_theme_font_size_override("font_size", 26)
	lbl_nom.add_theme_color_override("font_color", Color.WHITE)
	lbl_nom.add_theme_constant_override("outline_size", 2)
	lbl_nom.add_theme_color_override("font_outline_color", Color(0.18, 0.06, 0.50))
	lbl_nom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Badge "GRATIS"
	var lbl_gratis := Label.new()
	root.add_child(lbl_gratis)
	lbl_gratis.layout_mode = 0
	lbl_gratis.position    = Vector2(96, 46)
	lbl_gratis.size        = Vector2(150, 28)
	lbl_gratis.text        = "GRATIS"
	lbl_gratis.add_theme_font_size_override("font_size", 16)
	lbl_gratis.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))

	# Botón equipar/equipado
	var btn := Button.new()
	root.add_child(btn)
	btn.layout_mode = 0
	btn.position    = Vector2(total_w - 202, 18)
	btn.size        = Vector2(190, 50)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)
	_estilo_boton(btn, Color(0.35, 0.16, 0.72), Color(0.52, 0.30, 0.94))
	btn.pressed.connect(func():
		guardado_node.activar_skin("default")
		_actualizar_ui()
	)
	botones_skins["default"] = btn

# ─────────────────────────────────────────────────────────────
#  CARD INDIVIDUAL  — imagen completa del diseñador + botón invisible
# ─────────────────────────────────────────────────────────────
func _crear_card(skin_id: String, cfg: Dictionary, pos: Vector2) -> void:

	var root := Control.new()
	add_child(root)
	root.layout_mode   = 0
	root.position      = pos
	root.size          = Vector2(CARD_W, CARD_H)
	root.clip_contents = false

	# ── Imagen de la card (incluye estrella, personaje, nombre y botón) ─
	var img := TextureRect.new()
	root.add_child(img)
	img.layout_mode  = 0
	img.position     = Vector2(0, 0)
	img.size         = Vector2(CARD_W, CARD_H)
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	img.texture      = load(cfg["comprar"])   # estado inicial
	card_textures[skin_id] = img

	# ── Botón invisible sobre el área del botón en la imagen ─────────
	# La imagen del diseñador tiene el botón en el ~84–99 % inferior.
	var btn_y  : float = CARD_H * 0.835
	var btn_h  : float = CARD_H * 0.155
	var btn_mx : float = CARD_W * 0.09

	var btn := Button.new()
	root.add_child(btn)
	btn.layout_mode = 0
	btn.position    = Vector2(btn_mx, btn_y)
	btn.size        = Vector2(CARD_W - btn_mx * 2.0, btn_h)
	btn.flat        = true   # sin fondo ni borde — el diseño viene de la imagen
	btn.pressed.connect(_on_btn_skin.bind(skin_id))
	botones_skins[skin_id] = btn

	# ── Label de error "¡Faltan monedas!" (oculto por defecto) ───────
	var lbl_err := Label.new()
	root.add_child(lbl_err)
	lbl_err.layout_mode          = 0
	lbl_err.position             = Vector2(0.0, btn_y - 6.0)
	lbl_err.size                 = Vector2(CARD_W, btn_h + 12.0)
	lbl_err.text                 = "¡Faltan monedas!"
	lbl_err.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_err.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl_err.add_theme_font_size_override("font_size", 19)
	lbl_err.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	lbl_err.add_theme_color_override("font_shadow_color", Color.BLACK)
	lbl_err.add_theme_constant_override("shadow_offset_x", 1)
	lbl_err.add_theme_constant_override("shadow_offset_y", 1)
	lbl_err.visible = false
	labels_error[skin_id] = lbl_err

# ─────────────────────────────────────────────────────────────
#  ACTUALIZAR IMÁGENES SEGÚN ESTADO
# ─────────────────────────────────────────────────────────────
func _actualizar_ui() -> void:
	var datos       : Dictionary = guardado_node.cargar()
	var monedas     : int        = int(datos.get("monedas", 0))
	var skin_activa : String     = datos.get("skin_activa", "default")

	_actualizar_indicador_estrella(monedas)

	for skin_id in SKIN_ORDER:
		var comprada : bool        = guardado_node.skin_comprada(skin_id)
		var activa   : bool        = (skin_activa == skin_id)
		var img      : TextureRect = card_textures[skin_id]
		var cfg      : Dictionary  = SKINS_CONFIG[skin_id]
		var btn      : Button      = botones_skins[skin_id]

		if activa:
			img.texture  = load(cfg["equipado"])
			btn.disabled = true
		elif comprada:
			img.texture  = load(cfg["cambiar"])
			btn.disabled = false
		else:
			img.texture  = load(cfg["comprar"])
			btn.disabled = false

	# Botón de Mati Original
	var btn_def : Button = botones_skins.get("default")
	if btn_def:
		if skin_activa == "default":
			btn_def.text     = "✓ Equipado"
			btn_def.disabled = true
		else:
			btn_def.text     = "Equipar"
			btn_def.disabled = false

# ─────────────────────────────────────────────────────────────
#  ACCIÓN BOTÓN
# ─────────────────────────────────────────────────────────────
func _on_btn_skin(skin_id: String) -> void:
	if guardado_node.skin_comprada(skin_id):
		guardado_node.activar_skin(skin_id)
	else:
		var precio : int = SKINS_CONFIG[skin_id]["precio"]
		if not guardado_node.comprar_skin(skin_id, precio):
			# Sin monedas — mostrar label de error breve sobre la card
			_mostrar_error_monedas(skin_id)
			return
		guardado_node.activar_skin(skin_id)
	_actualizar_ui()

func _mostrar_error_monedas(skin_id: String) -> void:
	var lbl : Label = labels_error.get(skin_id)
	if lbl == null:
		return
	lbl.visible = true
	get_tree().create_timer(1.5).timeout.connect(func():
		lbl.visible = false
	)

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

func _volver() -> void:
	get_tree().change_scene_to_file("res://scenes/Mapa.tscn")

# ─────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────
func _estilo_panel(p: Panel, color: Color, radio: int) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                   = color
	s.corner_radius_top_left     = radio
	s.corner_radius_top_right    = radio
	s.corner_radius_bottom_left  = radio
	s.corner_radius_bottom_right = radio
	p.add_theme_stylebox_override("panel", s)

func _estilo_boton(btn: Button, cn: Color, ch: Color) -> void:
	for estado in ["normal", "hover", "pressed", "disabled"]:
		var s := StyleBoxFlat.new()
		match estado:
			"normal":   s.bg_color = cn
			"hover":    s.bg_color = ch
			"pressed":  s.bg_color = cn.darkened(0.2)
			"disabled": s.bg_color = cn.darkened(0.1)
		s.corner_radius_top_left     = 30
		s.corner_radius_top_right    = 30
		s.corner_radius_bottom_left  = 30
		s.corner_radius_bottom_right = 30
		btn.add_theme_stylebox_override(estado, s)

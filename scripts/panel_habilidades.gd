extends Control

# ═══════════════════════════════════════════════════════════════
#  PANEL HABILIDADES — pantalla accesible desde el Mapa
#  Muestra las 4 habilidades, sus costos y permite desbloquearlas.
#  Se integra igual que la tienda: TransitionManager.cambiar_escena
# ═══════════════════════════════════════════════════════════════

const SCR_W    : float = 1280.0
const SCR_H    : float = 720.0
const CARD_W   : float = 260.0
const CARD_H   : float = 320.0
const CARD_GAP : float = 28.0

var _habilidades = null
var _guardado    = null
var _lbl_monedas : Label = null
var _cards       : Dictionary = {}

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_habilidades = load("res://scripts/habilidades.gd").new()
	_guardado    = load("res://scripts/guardado.gd").new()
	_construir_ui()

# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	# Fondo
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.03, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Fondo galaxy (reutiliza el mismo que la tienda)
	const RUTA_FONDO = "res://assets/fondos/Fondo.png"
	if ResourceLoader.exists(RUTA_FONDO):
		var bg_tex := TextureRect.new()
		bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.texture      = load(RUTA_FONDO)
		bg_tex.modulate.a   = 0.5
		bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_tex)

	# Título
	var lbl_titulo := Label.new()
	lbl_titulo.text = "⚡ Habilidades de Mati"
	lbl_titulo.position = Vector2(0, 18)
	lbl_titulo.size     = Vector2(SCR_W, 50)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 38)
	lbl_titulo.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	add_child(lbl_titulo)

	# Monedas actuales
	var datos: Dictionary = _guardado.cargar()
	_lbl_monedas = Label.new()
	_lbl_monedas.position = Vector2(SCR_W - 220, 22)
	_lbl_monedas.size     = Vector2(200, 40)
	_lbl_monedas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_monedas.add_theme_font_size_override("font_size", 26)
	_lbl_monedas.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
	const RUTA_MONEDA = "res://assets/ui/Moneda.png"
	if ResourceLoader.exists(RUTA_MONEDA):
		var ico := TextureRect.new()
		ico.texture = load(RUTA_MONEDA)
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.position = Vector2(SCR_W - 250, 18)
		ico.size     = Vector2(36, 36)
		add_child(ico)
	_lbl_monedas.text = "%d" % int(datos.get("monedas", 0))
	add_child(_lbl_monedas)

	# Cards de habilidades
	var ids := _habilidades.get_todas()
	var total_w := ids.size() * CARD_W + (ids.size() - 1) * CARD_GAP
	var start_x := (SCR_W - total_w) * 0.5
	var card_y  : float = 100.0

	for i in ids.size():
		var id : String = ids[i]
		var x  := start_x + i * (CARD_W + CARD_GAP)
		_crear_card(id, Vector2(x, card_y))

	# Botón volver
	var btn_volver := Button.new()
	btn_volver.text = "← Volver"
	btn_volver.position = Vector2(30, SCR_H - 68)
	btn_volver.size     = Vector2(160, 50)
	btn_volver.add_theme_font_size_override("font_size", 22)
	var sty_v := StyleBoxFlat.new()
	sty_v.bg_color = Color(0.2, 0.2, 0.4)
	sty_v.corner_radius_top_left = 10; sty_v.corner_radius_top_right = 10
	sty_v.corner_radius_bottom_left = 10; sty_v.corner_radius_bottom_right = 10
	btn_volver.add_theme_stylebox_override("normal", sty_v)
	btn_volver.add_theme_stylebox_override("hover",  sty_v)
	btn_volver.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")
	)
	add_child(btn_volver)

# ─────────────────────────────────────────────────────────────
func _crear_card(id: String, pos: Vector2) -> void:
	var cfg    := _habilidades.get_config(id)
	var desbloqueada := _habilidades.esta_desbloqueada(id)
	var activa       := _habilidades.esta_activa(id)

	# Fondo card
	var card := Panel.new()
	card.position = pos
	card.size     = Vector2(CARD_W, CARD_H)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.10, 0.06, 0.28, 0.92) if not desbloqueada else Color(0.08, 0.20, 0.10, 0.95)
	sty.border_width_left   = 2; sty.border_width_right  = 2
	sty.border_width_top    = 2; sty.border_width_bottom  = 2
	sty.border_color = Color(0.6, 0.4, 1) if not desbloqueada else Color(0.3, 0.9, 0.3)
	sty.corner_radius_top_left = 16; sty.corner_radius_top_right = 16
	sty.corner_radius_bottom_left = 16; sty.corner_radius_bottom_right = 16
	card.add_theme_stylebox_override("panel", sty)
	add_child(card)

	# Icono
	var ruta_ico : String = cfg.get("icono", "")
	if ruta_ico != "" and ResourceLoader.exists(ruta_ico):
		var ico := TextureRect.new()
		ico.texture     = load(ruta_ico)
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.position = Vector2((CARD_W - 90) * 0.5, 18)
		ico.size     = Vector2(90, 90)
		if not desbloqueada:
			ico.modulate = Color(0.4, 0.4, 0.4)
		card.add_child(ico)
	else:
		var ph := ColorRect.new()
		ph.color    = Color(0.3, 0.3, 0.5)
		ph.position = Vector2((CARD_W - 80) * 0.5, 18)
		ph.size     = Vector2(80, 80)
		card.add_child(ph)

	# Nombre
	var lbl_nom := Label.new()
	lbl_nom.text = cfg.get("nombre", id)
	lbl_nom.position = Vector2(10, 120)
	lbl_nom.size     = Vector2(CARD_W - 20, 36)
	lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nom.add_theme_font_size_override("font_size", 18)
	lbl_nom.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.4) if desbloqueada else Color(0.9, 0.85, 1))
	card.add_child(lbl_nom)

	# Descripción
	var lbl_desc := Label.new()
	lbl_desc.text = cfg.get("descripcion", "")
	lbl_desc.position = Vector2(10, 162)
	lbl_desc.size     = Vector2(CARD_W - 20, 90)
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_font_size_override("font_size", 13)
	lbl_desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.9))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	card.add_child(lbl_desc)

	# Badge de estado / Botón acción
	if desbloqueada:
		var badge := Label.new()
		badge.text     = "✓ DESBLOQUEADA" if not activa else "⚡ ACTIVA"
		badge.position = Vector2(10, 262)
		badge.size     = Vector2(CARD_W - 20, 30)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 16)
		badge.add_theme_color_override("font_color",
			Color(0.3, 1, 0.3) if not activa else Color(1, 0.9, 0.1))
		card.add_child(badge)

		# Toggle activa/desactiva
		var btn := Button.new()
		btn.text = "Desactivar" if activa else "Activar"
		btn.position = Vector2((CARD_W - 180) * 0.5, 298)
		btn.size     = Vector2(180, 42)
		btn.add_theme_font_size_override("font_size", 18)
		var sty_b := StyleBoxFlat.new()
		sty_b.bg_color = Color(0.1, 0.5, 0.1) if not activa else Color(0.4, 0.1, 0.1)
		sty_b.corner_radius_top_left = 10; sty_b.corner_radius_top_right = 10
		sty_b.corner_radius_bottom_left = 10; sty_b.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", sty_b)
		btn.add_theme_stylebox_override("hover",  sty_b)
		btn.pressed.connect(func(): _toggle_habilidad(id))
		card.add_child(btn)
	else:
		# Costo
		var costo := int(cfg.get("costo", 0))
		var lbl_costo := Label.new()
		lbl_costo.text = "🪙 %d monedas" % costo
		lbl_costo.position = Vector2(10, 258)
		lbl_costo.size     = Vector2(CARD_W - 20, 32)
		lbl_costo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_costo.add_theme_font_size_override("font_size", 18)
		lbl_costo.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
		card.add_child(lbl_costo)

		var btn := Button.new()
		btn.text = "Desbloquear"
		btn.position = Vector2((CARD_W - 180) * 0.5, 294)
		btn.size     = Vector2(180, 46)
		btn.add_theme_font_size_override("font_size", 18)
		var sty_b := StyleBoxFlat.new()
		sty_b.bg_color = Color(0.4, 0.15, 0.7)
		sty_b.corner_radius_top_left = 10; sty_b.corner_radius_top_right = 10
		sty_b.corner_radius_bottom_left = 10; sty_b.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", sty_b)
		btn.add_theme_stylebox_override("hover",  sty_b)
		btn.pressed.connect(func(): _intentar_desbloquear(id))
		card.add_child(btn)

	_cards[id] = card

# ─────────────────────────────────────────────────────────────
func _intentar_desbloquear(id: String) -> void:
	var ok := _habilidades.desbloquear(id)
	if ok:
		_mostrar_animacion_desbloqueo(id)
		await get_tree().create_timer(1.5).timeout
		_refrescar()
	else:
		_mostrar_error_monedas()

func _toggle_habilidad(id: String) -> void:
	if _habilidades.esta_activa(id):
		_habilidades.desactivar(id)
	else:
		_habilidades.activar(id)
	_refrescar()

func _refrescar() -> void:
	# Eliminar cards viejas y reconstruir
	for id in _cards:
		if is_instance_valid(_cards[id]):
			_cards[id].queue_free()
	_cards.clear()

	var datos: Dictionary = _guardado.cargar()
	_lbl_monedas.text = "%d" % int(datos.get("monedas", 0))

	var ids := _habilidades.get_todas()
	var total_w := ids.size() * CARD_W + (ids.size() - 1) * CARD_GAP
	var start_x := (SCR_W - total_w) * 0.5
	for i in ids.size():
		_crear_card(ids[i], Vector2(start_x + i * (CARD_W + CARD_GAP), 100.0))

func _mostrar_animacion_desbloqueo(id: String) -> void:
	var cfg := _habilidades.get_config(id)
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0.05, 0.0, 0.15, 0.80), 0.25)

	var lbl := Label.new()
	lbl.text = "⚡ ¡%s desbloqueada!" % cfg.get("nombre", id)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 44)
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
	lbl.modulate.a = 0.0
	overlay.add_child(lbl)

	var tw2 := create_tween()
	tw2.tween_property(lbl, "modulate:a", 1.0, 0.3)
	tw2.tween_interval(0.8)
	tw2.tween_property(overlay, "modulate:a", 0.0, 0.3)
	tw2.tween_callback(overlay.queue_free)

	# Celebración
	var cel_script = load("res://scripts/celebracion.gd")
	if cel_script:
		cel_script.lanzar(get_tree().root)

func _mostrar_error_monedas() -> void:
	var lbl := Label.new()
	lbl.text = "¡Faltan monedas!"
	lbl.position = Vector2(0, SCR_H - 120)
	lbl.size     = Vector2(SCR_W, 40)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	lbl.modulate.a = 0.0
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.3)
	tw.tween_callback(lbl.queue_free)

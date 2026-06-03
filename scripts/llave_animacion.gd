extends Node

# ═══════════════════════════════════════════════════════════════
#  ANIMACIÓN DE LLAVE
#  Uso:  LlaveAnimacion.mostrar(get_tree().root, ruta_textura, callback)
#  Al terminar llama callback (sin argumentos) para continuar el flujo.
# ═══════════════════════════════════════════════════════════════

static func mostrar(parent: Node, ruta_llave: String, callback: Callable) -> void:
	var anim := _LlaveOverlay.new()
	anim.ruta      = ruta_llave
	anim.callback  = callback
	parent.add_child(anim)

# ─── Clase interna que maneja todo el overlay ─────────────────
class _LlaveOverlay extends CanvasLayer:
	var ruta     : String   = ""
	var callback : Callable

	var _bg       : ColorRect   = null
	var _img      : TextureRect = null
	var _titulo   : Label       = null
	var _subtitulo: Label       = null
	var _hint     : Label       = null
	var _destellos: Array       = []
	var _listo    : bool        = false

	func _ready() -> void:
		layer = 100   # encima de todo
		_construir()
		_animar()

	# ── Construcción del overlay ───────────────────────────────
	func _construir() -> void:
		# Fondo oscuro
		_bg = ColorRect.new()
		_bg.color = Color(0.0, 0.0, 0.0, 0.0)
		_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bg)

		# Imagen de la llave
		_img = TextureRect.new()
		_img.layout_mode  = 0
		_img.size         = Vector2(260.0, 260.0)
		_img.position     = Vector2(510.0, -320.0)   # empieza fuera de pantalla
		_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		_img.pivot_offset = Vector2(130.0, 130.0)
		if ResourceLoader.exists(ruta):
			_img.texture = load(ruta)
		add_child(_img)

		# Título "¡LLAVE OBTENIDA!"
		_titulo = Label.new()
		_titulo.layout_mode = 0
		_titulo.text = "¡LLAVE OBTENIDA!"
		_titulo.position  = Vector2(350.0, 430.0)
		_titulo.size      = Vector2(580.0, 80.0)
		_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_titulo.add_theme_font_size_override("font_size", 52)
		_titulo.add_theme_color_override("font_color", Color(1.0, 0.92, 0.15))
		_titulo.add_theme_color_override("font_shadow_color", Color(0.6, 0.3, 0.0, 0.9))
		_titulo.add_theme_constant_override("shadow_offset_x", 3)
		_titulo.add_theme_constant_override("shadow_offset_y", 3)
		_titulo.modulate.a = 0.0
		add_child(_titulo)

		# Subtítulo "¡Completaste el Mundo!"
		_subtitulo = Label.new()
		_subtitulo.layout_mode = 0
		_subtitulo.text = "¡Completaste el mundo!"
		_subtitulo.position  = Vector2(350.0, 500.0)
		_subtitulo.size      = Vector2(580.0, 50.0)
		_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_subtitulo.add_theme_font_size_override("font_size", 28)
		_subtitulo.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
		_subtitulo.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
		_subtitulo.add_theme_constant_override("shadow_offset_x", 2)
		_subtitulo.add_theme_constant_override("shadow_offset_y", 2)
		_subtitulo.modulate.a = 0.0
		add_child(_subtitulo)

		# Destellos (estrellas girando)
		var star_data := [
			{"pos": Vector2(380, 190), "size": 44, "delay": 0.55},
			{"pos": Vector2(840, 210), "size": 38, "delay": 0.65},
			{"pos": Vector2(300, 370), "size": 50, "delay": 0.70},
			{"pos": Vector2(920, 340), "size": 42, "delay": 0.60},
			{"pos": Vector2(560, 160), "size": 36, "delay": 0.80},
			{"pos": Vector2(700, 175), "size": 46, "delay": 0.75},
			{"pos": Vector2(430, 510), "size": 34, "delay": 0.85},
			{"pos": Vector2(820, 490), "size": 40, "delay": 0.72},
		]
		for d in star_data:
			var lbl := Label.new()
			lbl.text = "✨"
			lbl.layout_mode = 0
			lbl.position    = d["pos"]
			lbl.add_theme_font_size_override("font_size", d["size"])
			lbl.modulate.a  = 0.0
			lbl.scale       = Vector2(0.1, 0.1)
			lbl.pivot_offset = Vector2(d["size"] * 0.5, d["size"] * 0.5)
			add_child(lbl)
			_destellos.append({"lbl": lbl, "delay": d["delay"]})

		# Hint "Toca para continuar"
		_hint = Label.new()
		_hint.layout_mode = 0
		_hint.text = "▸ Toca para continuar"
		_hint.position  = Vector2(450.0, 622.0)
		_hint.add_theme_font_size_override("font_size", 22)
		_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.80))
		_hint.modulate.a = 0.0
		add_child(_hint)

	# ── Secuencia de animación ─────────────────────────────────
	func _animar() -> void:
		# 1. Fade in del fondo
		var tw1 := create_tween()
		tw1.tween_property(_bg, "color", Color(0.0, 0.0, 0.0, 0.82), 0.35)

		# 2. Llave cae desde arriba + gira + rebota
		var tw2 := create_tween()
		tw2.set_ease(Tween.EASE_OUT)
		tw2.set_trans(Tween.TRANS_BACK)
		tw2.tween_property(_img, "position:y", 220.0, 0.60).set_delay(0.15)

		# Giro completo de 360°
		var tw_rot := create_tween()
		tw_rot.set_ease(Tween.EASE_OUT)
		tw_rot.set_trans(Tween.TRANS_CUBIC)
		_img.rotation_degrees = -360.0
		tw_rot.tween_property(_img, "rotation_degrees", 0.0, 0.60).set_delay(0.15)

		# Escala pop-in
		_img.scale = Vector2(0.4, 0.4)
		var tw_sc := create_tween()
		tw_sc.set_ease(Tween.EASE_OUT)
		tw_sc.set_trans(Tween.TRANS_BACK)
		tw_sc.tween_property(_img, "scale", Vector2(1.0, 1.0), 0.55).set_delay(0.15)

		# 3. Destellos pop-in
		for d in _destellos:
			var lbl : Label = d["lbl"]
			var delay : float = d["delay"]
			var stw := create_tween()
			stw.set_ease(Tween.EASE_OUT)
			stw.set_trans(Tween.TRANS_BACK)
			stw.tween_property(lbl, "scale",      Vector2(1.0, 1.0), 0.30).set_delay(delay)
			stw.tween_property(lbl, "modulate:a", 1.0,               0.20).set_delay(delay)

		# 4. Texto fade-in
		var tw_txt := create_tween()
		tw_txt.set_ease(Tween.EASE_OUT)
		tw_txt.set_trans(Tween.TRANS_QUAD)
		tw_txt.tween_property(_titulo,    "modulate:a", 1.0, 0.30).set_delay(0.70)
		tw_txt.tween_property(_subtitulo, "modulate:a", 1.0, 0.25).set_delay(0.85)

		# 5. Flotación continua de la llave
		var tw_float := create_tween()
		tw_float.set_loops()
		tw_float.tween_property(_img, "position:y", 230.0, 1.0).set_delay(1.0)
		tw_float.tween_property(_img, "position:y", 210.0, 1.0)

		# 6. Hint aparece después de 1.5s → ya se puede cerrar
		var tw_hint := create_tween()
		tw_hint.tween_property(_hint, "modulate:a", 1.0, 0.30).set_delay(1.5)
		tw_hint.tween_callback(func(): _listo = true)

	# ── Input — toca para cerrar ───────────────────────────────
	func _input(event: InputEvent) -> void:
		if not _listo:
			return
		if event is InputEventMouseButton and event.pressed:
			_cerrar()

	func _cerrar() -> void:
		_listo = false
		# Llave sale volando hacia arriba
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_ease(Tween.EASE_IN)
		tw.set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_img,       "position:y",  -400.0, 0.40)
		tw.tween_property(_img,       "modulate:a",     0.0, 0.35)
		tw.tween_property(_titulo,    "modulate:a",     0.0, 0.25)
		tw.tween_property(_subtitulo, "modulate:a",     0.0, 0.25)
		tw.tween_property(_hint,      "modulate:a",     0.0, 0.20)
		for d in _destellos:
			tw.tween_property(d["lbl"] as Label, "modulate:a", 0.0, 0.20)
		tw.tween_property(_bg, "color", Color(0.0, 0.0, 0.0, 0.0), 0.40)
		tw.chain().tween_callback(func():
			queue_free()
			if callback.is_valid():
				callback.call()
		)

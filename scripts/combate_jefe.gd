extends Control

# ═══════════════════════════════════════════════════════════════
#  COMBATE JEFE — Pantalla de batalla matemática reutilizable
#
#  Integración:
#    var datos = {
#        "jefe_nombre":    "Jefe Hongo",
#        "jefe_textura":   "res://assets/npcs/Jefe hongo.PNG",
#        "jefe_vida_max":  10,          # preguntas correctas para derrotar al jefe
#        "seccion":        18,          # ID de guardado
#        "tipo_op":        "mult",      # "suma","resta","mult","mixto"
#        "nivel_op":       3,
#        "total_preguntas":10,
#        "monedas":        10,
#        "escena_origen":  "res://scenes/Mundo3Explorar.tscn"
#    }
#    TransitionManager.cambiar_escena_con_datos("res://scenes/CombateJefe.tscn", datos)
# ═══════════════════════════════════════════════════════════════

const TOTAL_OPCIONES  : int   = 4
const ENERGIA_MAX     : int   = 5    # respuestas correctas para ataque especial
const VIDA_MATI_MAX   : int   = 5    # vidas de Mati (errores permitidos)
const MONEDAS_DEFAULT : int   = 8

# Colores de UI
const COL_CORRECTO   := Color(0.15, 0.80, 0.30)
const COL_INCORRECTO := Color(0.90, 0.20, 0.20)
const COL_NORMAL     := Color(0.18, 0.22, 0.45, 0.95)
const COL_ESPECIAL   := Color(0.90, 0.60, 0.00)

# ─────────────────────────────────────────────────────────────
#  ESTADO
# ─────────────────────────────────────────────────────────────
var _config          : Dictionary = {}
var _operaciones                  = null
var _guardado                     = null
var _animador                     = null
var _habilidades                  = null
var _efectos                      = null

# Efectos de habilidades activas
var _escudo_activo   : bool = false   # bloquea primer daño si "escudo" equipado
var _rayo_equipado   : bool = false   # duplica daño especial si "rayo" equipado

var _vida_jefe       : int  = 0
var _vida_jefe_max   : int  = 10
var _vida_mati       : int  = VIDA_MATI_MAX
var _energia         : int  = 0
var _racha_correctas : int  = 0
var _pregunta_actual : Dictionary = {}
var _respuesta_ok    : int  = 0
var _botones_vals    : Array = []
var _turno_bloqueado : bool = false
var _especial_listo  : bool = false
var _total_pregs     : int  = 0
var _pregs_respondidas: int = 0
var _aciertos        : int  = 0

# Nodos de UI (creados en _ready)
var _lbl_jefe_nombre : Label
var _lbl_mati_nombre : Label
var _barra_jefe      : ProgressBar
var _barra_mati      : ProgressBar
var _barra_energia   : ProgressBar
var _lbl_operacion   : Label
var _botones         : Array = []
var _img_jefe        : TextureRect
var _img_mati        : TextureRect
var _lbl_feedback    : Label
var _btn_especial    : Button
var _lbl_racha       : Label
var _contenedor_raiz : Control

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_operaciones  = load("res://scripts/operaciones.gd").new()
	_guardado     = load("res://scripts/guardado.gd").new()
	_animador     = load("res://scripts/animador_personaje.gd")
	_habilidades  = load("res://scripts/habilidades.gd").new()
	_efectos      = load("res://scripts/efectos_ui.gd")

	_rayo_equipado  = _habilidades.esta_activa("rayo")
	_escudo_activo  = _habilidades.esta_activa("escudo")

	# Leer configuración (pasada por TransitionManager o defaults)
	_config = _leer_config()
	_vida_jefe_max  = _config.get("jefe_vida_max", 10)
	_vida_jefe      = _vida_jefe_max
	_total_pregs    = _config.get("total_preguntas", 10)
	_vida_mati      = VIDA_MATI_MAX

	_construir_ui()
	_entrada_jefe()

# ─────────────────────────────────────────────────────────────
#  CONFIGURACIÓN — soporta datos pasados via save temporal
# ─────────────────────────────────────────────────────────────
func _leer_config() -> Dictionary:
	var defaults := {
		"jefe_nombre":   "Jefe Hongo",
		"jefe_textura":  "res://assets/npcs/Jefe hongo.PNG",
		"jefe_vida_max": 10,
		"seccion":       18,
		"tipo_op":       "mult_mixto",
		"nivel_op":      3,
		"total_preguntas": 10,
		"monedas":       MONEDAS_DEFAULT,
		"escena_origen": "res://scenes/Mundo3Explorar.tscn"
	}
	# Intentar cargar desde archivo temporal
	const TEMP := "user://combate_config.json"
	if FileAccess.file_exists(TEMP):
		var f := FileAccess.open(TEMP, FileAccess.READ)
		if f:
			var j := JSON.new()
			if j.parse(f.get_as_text()) == OK:
				var d = j.data
				for k in d:
					defaults[k] = d[k]
			f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	return defaults

static func guardar_config(cfg: Dictionary) -> void:
	const TEMP := "user://combate_config.json"
	var f := FileAccess.open(TEMP, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))
		f.close()

# ─────────────────────────────────────────────────────────────
#  CONSTRUCCIÓN DE UI
# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	# Fondo degradado
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.02, 0.12)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	_contenedor_raiz = self

	# ── Área de combate (arriba) ──────────────────────────────
	var zona_combate := HBoxContainer.new()
	zona_combate.set_anchors_preset(Control.PRESET_FULL_RECT)
	zona_combate.position = Vector2(0, 0)
	zona_combate.size     = Vector2(1280, 380)
	zona_combate.alignment = BoxContainer.ALIGNMENT_CENTER
	zona_combate.add_theme_constant_override("separation", 60)
	add_child(zona_combate)

	# Panel Mati
	var panel_mati := _crear_panel_luchador(true)
	zona_combate.add_child(panel_mati)

	# VS label
	var lbl_vs := Label.new()
	lbl_vs.text = "VS"
	lbl_vs.add_theme_font_size_override("font_size", 48)
	lbl_vs.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	lbl_vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_vs.custom_minimum_size = Vector2(80, 380)
	zona_combate.add_child(lbl_vs)

	# Panel Jefe
	var panel_jefe := _crear_panel_luchador(false)
	zona_combate.add_child(panel_jefe)

	# ── Zona matemática (abajo) ───────────────────────────────
	_construir_zona_math()

func _crear_panel_luchador(es_mati: bool) -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.custom_minimum_size = Vector2(380, 380)
	panel.add_theme_constant_override("separation", 8)

	# Nombre
	var lbl_nom := Label.new()
	lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nom.add_theme_font_size_override("font_size", 22)
	lbl_nom.add_theme_color_override("font_color", Color(1, 1, 1))
	panel.add_child(lbl_nom)

	# Barra de vida
	var barra := ProgressBar.new()
	barra.custom_minimum_size = Vector2(300, 22)
	barra.max_value = 100
	barra.value     = 100
	barra.show_percentage = false
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.15, 0.80, 0.25) if es_mati else Color(0.80, 0.15, 0.15)
	sty.corner_radius_top_left = 6; sty.corner_radius_top_right = 6
	sty.corner_radius_bottom_left = 6; sty.corner_radius_bottom_right = 6
	barra.add_theme_stylebox_override("fill", sty)
	var sty_bg := StyleBoxFlat.new()
	sty_bg.bg_color = Color(0.1, 0.1, 0.1)
	barra.add_theme_stylebox_override("background", sty_bg)
	panel.add_child(barra)

	# Imagen
	var img := TextureRect.new()
	img.stretch_mode    = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.expand_mode     = TextureRect.EXPAND_IGNORE_SIZE
	img.custom_minimum_size = Vector2(200, 240)
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(img)

	if es_mati:
		lbl_nom.text  = "MATI"
		_lbl_mati_nombre = lbl_nom
		_barra_mati      = barra
		_img_mati        = img
		# Cargar textura de Mati (skin activa)
		var datos := _guardado.cargar()
		var skin  : String = datos.get("skin_activa", "clasica")
		var rutas := {
			"clasica":  "res://assets/personajes/mati_frente.PNG",
			"ninja":    "res://assets/personajes/mati_ninja.PNG",
			"escolar":  "res://assets/personajes/mati_escolar.PNG",
			"fachero":  "res://assets/personajes/mati_fachero.PNG",
		}
		var ruta := rutas.get(skin, rutas["clasica"])
		if ResourceLoader.exists(ruta):
			img.texture = load(ruta)

		# Barra energía debajo de Mati
		var lbl_e := Label.new()
		lbl_e.text = "⚡ ENERGÍA"
		lbl_e.add_theme_font_size_override("font_size", 14)
		lbl_e.add_theme_color_override("font_color", Color(1, 0.85, 0))
		lbl_e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(lbl_e)

		_barra_energia = ProgressBar.new()
		_barra_energia.custom_minimum_size = Vector2(300, 16)
		_barra_energia.max_value = ENERGIA_MAX
		_barra_energia.value     = 0
		_barra_energia.show_percentage = false
		var sty_en := StyleBoxFlat.new()
		sty_en.bg_color = Color(1.0, 0.75, 0.0)
		sty_en.corner_radius_top_left = 4; sty_en.corner_radius_top_right = 4
		sty_en.corner_radius_bottom_left = 4; sty_en.corner_radius_bottom_right = 4
		_barra_energia.add_theme_stylebox_override("fill", sty_en)
		_barra_energia.add_theme_stylebox_override("background", sty_bg)
		panel.add_child(_barra_energia)

	else:
		lbl_nom.text = _config.get("jefe_nombre", "Jefe").to_upper()
		_lbl_jefe_nombre = lbl_nom
		_barra_jefe      = barra
		_img_jefe        = img
		var ruta_j : String = _config.get("jefe_textura", "")
		if ruta_j != "" and ResourceLoader.exists(ruta_j):
			img.texture = load(ruta_j)

	return panel

func _construir_zona_math() -> void:
	# Fondo panel matemático
	var panel_math := ColorRect.new()
	panel_math.color  = Color(0.08, 0.06, 0.20, 0.95)
	panel_math.position = Vector2(0, 380)
	panel_math.size     = Vector2(1280, 340)
	add_child(panel_math)

	# Label feedback (correcto/incorrecto)
	_lbl_feedback = Label.new()
	_lbl_feedback.position = Vector2(0, 385)
	_lbl_feedback.size     = Vector2(1280, 36)
	_lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_feedback.add_theme_font_size_override("font_size", 24)
	_lbl_feedback.add_theme_color_override("font_color", Color(1, 1, 0.3))
	_lbl_feedback.visible = false
	add_child(_lbl_feedback)

	# Label racha
	_lbl_racha = Label.new()
	_lbl_racha.position = Vector2(1050, 390)
	_lbl_racha.size     = Vector2(220, 30)
	_lbl_racha.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lbl_racha.add_theme_font_size_override("font_size", 18)
	_lbl_racha.add_theme_color_override("font_color", Color(1, 0.85, 0))
	_lbl_racha.visible = false
	add_child(_lbl_racha)

	# Operación matemática
	_lbl_operacion = Label.new()
	_lbl_operacion.position = Vector2(0, 428)
	_lbl_operacion.size     = Vector2(1280, 60)
	_lbl_operacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_operacion.add_theme_font_size_override("font_size", 46)
	_lbl_operacion.add_theme_color_override("font_color", Color(1, 1, 1))
	_lbl_operacion.text = "?"
	add_child(_lbl_operacion)

	# Botones de respuesta (2×2)
	var grid := GridContainer.new()
	grid.columns  = 2
	grid.position = Vector2(290, 500)
	grid.size     = Vector2(700, 160)
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 14)
	add_child(grid)

	for i in TOTAL_OPCIONES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(330, 64)
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color(1, 1, 1))
		var sty := StyleBoxFlat.new()
		sty.bg_color = COL_NORMAL
		sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
		sty.corner_radius_bottom_left = 12; sty.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal",  sty)
		btn.add_theme_stylebox_override("hover",   sty)
		btn.add_theme_stylebox_override("pressed", sty)
		btn.pressed.connect(_on_respuesta.bind(i))
		_botones.append(btn)
		grid.add_child(btn)

	# Botón ataque especial
	_btn_especial = Button.new()
	_btn_especial.text = "⚡ ATAQUE ESPECIAL"
	_btn_especial.position = Vector2(490, 672)
	_btn_especial.size     = Vector2(300, 46)
	_btn_especial.add_theme_font_size_override("font_size", 20)
	_btn_especial.add_theme_color_override("font_color", Color(0.1, 0.05, 0))
	var sty_esp := StyleBoxFlat.new()
	sty_esp.bg_color = Color(1.0, 0.70, 0.0)
	sty_esp.corner_radius_top_left = 10; sty_esp.corner_radius_top_right = 10
	sty_esp.corner_radius_bottom_left = 10; sty_esp.corner_radius_bottom_right = 10
	_btn_especial.add_theme_stylebox_override("normal",  sty_esp)
	_btn_especial.add_theme_stylebox_override("hover",   sty_esp)
	_btn_especial.add_theme_stylebox_override("pressed", sty_esp)
	_btn_especial.disabled = true
	_btn_especial.modulate.a = 0.4
	_btn_especial.pressed.connect(_usar_ataque_especial)
	add_child(_btn_especial)

# ─────────────────────────────────────────────────────────────
#  ENTRADA DEL JEFE (animación dramática)
# ─────────────────────────────────────────────────────────────
func _entrada_jefe() -> void:
	_turno_bloqueado = true
	if _img_jefe:
		_animador.jefe_entrada(_img_jefe, _img_jefe.position)
		# Zoom dramático al presentar al jefe
		if _efectos:
			_efectos.zoom_jefe(self, 1.05, 0.55)
	await get_tree().create_timer(0.9).timeout
	_turno_bloqueado = false
	_nueva_pregunta()

# ─────────────────────────────────────────────────────────────
#  GENERAR PREGUNTA
# ─────────────────────────────────────────────────────────────
func _nueva_pregunta() -> void:
	if _turno_bloqueado:
		return
	_lbl_feedback.visible = false

	var nivel := int(_config.get("nivel_op", 3))
	var tipo  : String = _config.get("tipo_op", "mult_mixto")
	var op    : Dictionary = _generar_op_tipo(nivel, tipo)

	_pregunta_actual = op
	_respuesta_ok    = op["respuesta"]
	_lbl_operacion.text = "%d %s %d = ?" % [op["n1"], op["op"], op["n2"]]

	# Generar opciones únicas
	var opciones : Array = [_respuesta_ok]
	var intentos := 0
	while opciones.size() < TOTAL_OPCIONES and intentos < 50:
		intentos += 1
		var dist := randi_range(1, max(3, int(_respuesta_ok * 0.3) + 2))
		var val  := _respuesta_ok + (dist if randi() % 2 == 0 else -dist)
		if val >= 0 and not opciones.has(val):
			opciones.append(val)
	opciones.shuffle()
	_botones_vals = opciones

	for i in TOTAL_OPCIONES:
		if i < _botones.size() and i < opciones.size():
			_botones[i].text     = str(opciones[i])
			_botones[i].disabled = false
			_restablecer_color_btn(i)

func _generar_op_tipo(nivel: int, tipo: String) -> Dictionary:
	match tipo:
		"mult":
			var tabla    := int(_config.get("tabla", randi_range(2, 9)))
			var factor   := randi_range(2, 9)
			return {"n1": tabla, "op": "×", "n2": factor, "respuesta": tabla * factor}
		"mult_mixto":
			var n1 := randi_range(int(_config.get("min", 3)), int(_config.get("max", 9)))
			var n2 := randi_range(int(_config.get("min_factor", 2)), 9)
			return {"n1": n1, "op": "×", "n2": n2, "respuesta": n1 * n2}
		"suma":
			var n1 := randi_range(5, 40)
			var n2 := randi_range(1, 20)
			return {"n1": n1, "op": "+", "n2": n2, "respuesta": n1 + n2}
		"resta":
			var n1 := randi_range(10, 50)
			var n2 := randi_range(1, int(n1 * 0.8))
			return {"n1": n1, "op": "−", "n2": n2, "respuesta": n1 - n2}
		_:  # mixto
			return _operaciones.generar_operacion(nivel)

# ─────────────────────────────────────────────────────────────
#  RESPUESTA DEL JUGADOR
# ─────────────────────────────────────────────────────────────
func _on_respuesta(idx: int) -> void:
	if _turno_bloqueado:
		return
	_turno_bloqueado = true
	for btn in _botones:
		btn.disabled = true

	var val_elegido := _botones_vals[idx]
	var correcto    := val_elegido == _respuesta_ok
	_pregs_respondidas += 1

	if correcto:
		_aciertos += 1
		_racha_correctas += 1
		_energia = min(_energia + 1, ENERGIA_MAX)
		_barra_energia.value = _energia

		if _racha_correctas >= 2:
			_lbl_racha.text    = "🔥 RACHA x%d" % _racha_correctas
			_lbl_racha.visible = true

		_especial_listo = (_energia >= ENERGIA_MAX)
		_btn_especial.disabled  = not _especial_listo
		_btn_especial.modulate.a = 1.0 if _especial_listo else 0.4

		_colorear_btn(idx, COL_CORRECTO)
		_feedback("¡Correcto! +⚡", Color(0.3, 1.0, 0.4))
		if _efectos:
			_efectos.flash_correcto(get_tree().root)
		MusicaManager.play_sfx("correcto")
		await get_tree().create_timer(0.35).timeout

		# Mati ataca
		if _img_mati:
			_animador.interaccion(_img_mati)
		await get_tree().create_timer(0.3).timeout

		_dañar_jefe(1)
	else:
		_racha_correctas = 0
		_lbl_racha.visible = false

		_colorear_btn(idx, COL_INCORRECTO)
		_feedback("¡Incorrecto!", Color(1.0, 0.3, 0.3))
		if _efectos:
			_efectos.flash_incorrecto(get_tree().root)
			_efectos.sacudida(self, 4.0, 0.25)
		await get_tree().create_timer(0.35).timeout

		if _img_mati:
			_animador.error_respuesta(_img_mati)
		await get_tree().create_timer(0.3).timeout

		# Jefe contraataca
		if _img_jefe:
			_animador.jefe_ataca(_img_jefe, -1.0)
		await get_tree().create_timer(0.25).timeout
		_dañar_mati()

	await get_tree().create_timer(0.2).timeout
	_turno_bloqueado = false

	if _vida_jefe <= 0:
		_victoria()
		return
	if _vida_mati <= 0:
		_derrota()
		return
	if _pregs_respondidas >= _total_pregs:
		# Fin de preguntas → si jefe tiene vida, derrota por tiempo
		if _vida_jefe > 0:
			_derrota()
		return

	_nueva_pregunta()

# ─────────────────────────────────────────────────────────────
#  ATAQUE ESPECIAL
# ─────────────────────────────────────────────────────────────
func _usar_ataque_especial() -> void:
	if _turno_bloqueado or not _especial_listo:
		return
	_turno_bloqueado = true
	_energia = 0
	_especial_listo = false
	_barra_energia.value = 0
	_btn_especial.disabled  = true
	_btn_especial.modulate.a = 0.4

	_feedback("⚡ ¡ATAQUE ESPECIAL!", COL_ESPECIAL)
	if _img_mati:
		_animador.victoria(_img_mati)
	if _efectos:
		_efectos.flash_dorado(get_tree().root)
	await get_tree().create_timer(0.5).timeout

	var dmg_especial := 6 if _rayo_equipado else 3
	if _efectos and _img_jefe:
		var pos_jefe := _img_jefe.get_global_rect().get_center()
		_efectos.explosion(get_tree().root, pos_jefe, Color(1.0, 0.65, 0.1))
	_dañar_jefe(dmg_especial)
	await get_tree().create_timer(0.4).timeout
	_turno_bloqueado = false

	if _vida_jefe <= 0:
		_victoria()
		return
	_nueva_pregunta()

# ─────────────────────────────────────────────────────────────
#  DAÑO AL JEFE
# ─────────────────────────────────────────────────────────────
func _dañar_jefe(cantidad: int) -> void:
	_vida_jefe = max(0, _vida_jefe - cantidad)
	var pct := float(_vida_jefe) / float(_vida_jefe_max) * 100.0
	var tw := create_tween()
	tw.tween_property(_barra_jefe, "value", pct, 0.3)
	if _img_jefe:
		_animador.jefe_daño(_img_jefe)
	_mostrar_numero_daño(str(-cantidad), _img_jefe, Color(1, 0.3, 0.3))

func _dañar_mati() -> void:
	if _escudo_activo:
		_escudo_activo = false
		_feedback("🛡 ¡Escudo absorbió el golpe!", Color(0.3, 0.7, 1))
		return
	_vida_mati = max(0, _vida_mati - 1)
	var pct := float(_vida_mati) / float(VIDA_MATI_MAX) * 100.0
	var tw := create_tween()
	tw.tween_property(_barra_mati, "value", pct, 0.3)
	if _img_mati:
		_animador.daño(_img_mati)
	_mostrar_numero_daño("-1", _img_mati, Color(1, 0.5, 0.5))

func _mostrar_numero_daño(texto: String, cerca_de: Control, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", color)
	var pos := Vector2(640, 300) if cerca_de == null else cerca_de.global_position + Vector2(randf_range(-30, 30), -20)
	lbl.position = pos
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", pos.y - 60, 0.6)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(lbl.queue_free)

# ─────────────────────────────────────────────────────────────
#  VICTORIA
# ─────────────────────────────────────────────────────────────
func _victoria() -> void:
	_turno_bloqueado = true
	_lbl_operacion.text = ""
	for btn in _botones:
		btn.visible = false
	_btn_especial.visible = false

	# Animación de derrota del jefe
	if _img_jefe:
		_animador.jefe_derrota(_img_jefe)
		if _efectos:
			var pos_j := _img_jefe.get_global_rect().get_center()
			_efectos.explosion(get_tree().root, pos_j, Color(1.0, 0.5, 0.1), 120.0)
	if _img_mati:
		await get_tree().create_timer(0.4).timeout
		_animador.victoria(_img_mati)
		if _efectos:
			_efectos.estrella_burst(get_tree().root, _img_mati.get_global_rect().get_center())

	await get_tree().create_timer(0.8).timeout

	# Celebración
	var cel_script = load("res://scripts/celebracion.gd")
	if cel_script:
		cel_script.lanzar(get_tree().root)
	if get_node_or_null("/root/MusicaManager"):
		MusicaManager.musica_victoria()

	await get_tree().create_timer(0.6).timeout

	# Guardar progreso
	var seccion_id := int(_config.get("seccion", 18))
	var monedas_ganar := int(_config.get("monedas", MONEDAS_DEFAULT))
	var perfecta := (_aciertos == _total_pregs)
	if perfecta:
		monedas_ganar += 5

	var datos := _guardado.cargar()
	var secciones : Dictionary = datos.get("secciones", {})
	var key := str(seccion_id)
	var anterior = secciones.get(key, {})
	secciones[key] = {
		"completada": true,
		"perfecta": perfecta or anterior.get("perfecta", false)
	}
	_guardado.guardar(
		datos.get("nombre", "Jugador"),
		int(datos.get("nivel", 1)),
		int(datos.get("estrellas", 0)),
		int(datos.get("monedas", 0)) + monedas_ganar,
		datos.get("mundo1_completado", false),
		secciones
	)

	_mostrar_panel_victoria(monedas_ganar, perfecta)

func _mostrar_panel_victoria(monedas: int, perfecta: bool) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0.0, 0.0, 0.0, 0.7), 0.4)

	var panel := VBoxContainer.new()
	panel.position = Vector2(390, 170)
	panel.size     = Vector2(500, 380)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 18)
	overlay.add_child(panel)

	# Fondo del panel
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.12, 0.05, 0.95)
	panel.add_child(bg)

	var lbl_titulo := Label.new()
	lbl_titulo.text = "🏆 ¡VICTORIA!"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 44)
	lbl_titulo.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
	panel.add_child(lbl_titulo)

	if perfecta:
		var lbl_p := Label.new()
		lbl_p.text = "⭐ ¡Perfecta!"
		lbl_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_p.add_theme_font_size_override("font_size", 26)
		lbl_p.add_theme_color_override("font_color", Color(1, 0.8, 0))
		panel.add_child(lbl_p)

	var lbl_mon := Label.new()
	lbl_mon.text = "+%d monedas" % monedas
	lbl_mon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mon.add_theme_font_size_override("font_size", 28)
	lbl_mon.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	panel.add_child(lbl_mon)

	var lbl_acc := Label.new()
	lbl_acc.text = "Aciertos: %d / %d" % [_aciertos, _total_pregs]
	lbl_acc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_acc.add_theme_font_size_override("font_size", 22)
	lbl_acc.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	panel.add_child(lbl_acc)

	var btn_cont := Button.new()
	btn_cont.text = "Continuar"
	btn_cont.custom_minimum_size = Vector2(200, 52)
	btn_cont.add_theme_font_size_override("font_size", 24)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.1, 0.65, 0.2)
	sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
	sty.corner_radius_bottom_left = 12; sty.corner_radius_bottom_right = 12
	btn_cont.add_theme_stylebox_override("normal", sty)
	btn_cont.add_theme_stylebox_override("hover",  sty)
	btn_cont.add_theme_stylebox_override("pressed", sty)
	var escena_origen : String = _config.get("escena_origen", "res://scenes/Mapa.tscn")
	btn_cont.pressed.connect(func():
		TransitionManager.cambiar_escena(escena_origen)
	)
	panel.add_child(btn_cont)

# ─────────────────────────────────────────────────────────────
#  DERROTA
# ─────────────────────────────────────────────────────────────
func _derrota() -> void:
	_turno_bloqueado = true
	for btn in _botones:
		btn.visible = false
	_btn_especial.visible = false

	_feedback("¡El jefe te venció!", Color(1, 0.4, 0.4))

	await get_tree().create_timer(0.8).timeout
	_mostrar_panel_derrota()

func _mostrar_panel_derrota() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0.0, 0.0, 0.0, 0.75), 0.4)

	var panel := VBoxContainer.new()
	panel.position = Vector2(390, 200)
	panel.size     = Vector2(500, 320)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 20)
	overlay.add_child(panel)

	var lbl_t := Label.new()
	lbl_t.text = "😵 ¡Inténtalo de nuevo!"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 36)
	lbl_t.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	panel.add_child(lbl_t)

	var lbl_s := Label.new()
	lbl_s.text = "No pierdes tu progreso anterior."
	lbl_s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_s.add_theme_font_size_override("font_size", 20)
	lbl_s.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	panel.add_child(lbl_s)

	var btn_reintentar := Button.new()
	btn_reintentar.text = "🔄 Reintentar"
	btn_reintentar.custom_minimum_size = Vector2(200, 50)
	btn_reintentar.add_theme_font_size_override("font_size", 22)
	var sty_r := StyleBoxFlat.new()
	sty_r.bg_color = Color(0.6, 0.15, 0.15)
	sty_r.corner_radius_top_left = 12; sty_r.corner_radius_top_right = 12
	sty_r.corner_radius_bottom_left = 12; sty_r.corner_radius_bottom_right = 12
	btn_reintentar.add_theme_stylebox_override("normal", sty_r)
	btn_reintentar.add_theme_stylebox_override("hover",  sty_r)
	btn_reintentar.add_theme_stylebox_override("pressed", sty_r)
	btn_reintentar.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/CombateJefe.tscn")
	)
	panel.add_child(btn_reintentar)

	var btn_salir := Button.new()
	btn_salir.text = "Volver al mapa"
	btn_salir.custom_minimum_size = Vector2(200, 46)
	btn_salir.add_theme_font_size_override("font_size", 20)
	var sty_s := StyleBoxFlat.new()
	sty_s.bg_color = Color(0.2, 0.2, 0.2)
	sty_s.corner_radius_top_left = 12; sty_s.corner_radius_top_right = 12
	sty_s.corner_radius_bottom_left = 12; sty_s.corner_radius_bottom_right = 12
	btn_salir.add_theme_stylebox_override("normal", sty_s)
	btn_salir.add_theme_stylebox_override("hover",  sty_s)
	btn_salir.add_theme_stylebox_override("pressed", sty_s)
	btn_salir.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")
	)
	panel.add_child(btn_salir)

# ─────────────────────────────────────────────────────────────
#  HELPERS UI
# ─────────────────────────────────────────────────────────────
func _feedback(texto: String, color: Color) -> void:
	_lbl_feedback.text = texto
	_lbl_feedback.add_theme_color_override("font_color", color)
	_lbl_feedback.visible = true
	_lbl_feedback.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(_lbl_feedback, "modulate:a", 0.0, 0.3)

func _colorear_btn(idx: int, color: Color) -> void:
	if idx >= _botones.size():
		return
	var sty := StyleBoxFlat.new()
	sty.bg_color = color
	sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
	sty.corner_radius_bottom_left = 12; sty.corner_radius_bottom_right = 12
	_botones[idx].add_theme_stylebox_override("normal", sty)

func _restablecer_color_btn(idx: int) -> void:
	if idx >= _botones.size():
		return
	var sty := StyleBoxFlat.new()
	sty.bg_color = COL_NORMAL
	sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
	sty.corner_radius_bottom_left = 12; sty.corner_radius_bottom_right = 12
	_botones[idx].add_theme_stylebox_override("normal",  sty)
	_botones[idx].add_theme_stylebox_override("hover",   sty)
	_botones[idx].add_theme_stylebox_override("pressed", sty)

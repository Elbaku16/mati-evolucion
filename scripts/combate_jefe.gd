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
var _lbl_jefe_nombre  : Label
var _lbl_mati_nombre  : Label
var _barra_jefe       : ProgressBar
var _barra_mati       : ProgressBar
var _lbl_operacion    : Label
var _img_jefe         : TextureRect
var _img_mati         : TextureRect
var _lbl_feedback     : Label
var _contenedor_raiz  : Control

# Sistema de flechas — opciones flotantes
var _opciones_nodos   : Array = []   # Array de Control (estrella + número)
var _seleccion_actual : int   = 0    # índice 0-3 de la opción resaltada
var _mati_y_origen    : float = 0.0  # posición y base de Mati
var _alturas_opciones : Array = []   # posiciones y de cada opción

# Bola verde del jefe (temporizador visual)
var _bola_jefe        : Control = null
var _tween_bola       : Tween   = null

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
	# Fondo bosque de hongos
	var fondo := TextureRect.new()
	var tex_path := "res://assets/fondos/fondo_mundo3.PNG"
	if ResourceLoader.exists(tex_path):
		fondo.texture = load(tex_path)
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	_contenedor_raiz = self

	# ── Sprites posicionados directo sobre el fondo ──────────────
	_crear_panel_luchador(true)   # crea y posiciona _img_mati
	_crear_panel_luchador(false)  # crea y posiciona _img_jefe

	# ── Zona matemática (abajo) ───────────────────────────────
	_construir_zona_math()

func _crear_panel_luchador(es_mati: bool) -> void:
	var sty_bg := StyleBoxFlat.new()
	sty_bg.bg_color = Color(0.1, 0.1, 0.1)

	# Imagen del personaje — posición absoluta sobre el fondo
	var img := TextureRect.new()
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE

	if es_mati:
		img.position = Vector2(80, 160)
		img.size     = Vector2(220, 280)
		img.modulate = Color(1, 1, 1, 1)
		add_child(img)
		_img_mati = img

		var datos: Dictionary = _guardado.cargar()
		var skin  : String = datos.get("skin_activa", "clasica")
		var rutas := {
			"clasica":  "res://assets/personajes/mati_frente.PNG",
			"ninja":    "res://assets/personajes/mati_ninja.PNG",
			"escolar":  "res://assets/personajes/mati_escolar.PNG",
			"fachero":  "res://assets/personajes/mati_fachero.PNG",
		}
		var ruta: String = rutas.get(skin, rutas["clasica"])
		if ResourceLoader.exists(ruta):
			img.texture = load(ruta)

		# Barra vida Mati — esquina superior izquierda
		var lbl_nom := Label.new()
		lbl_nom.text = "MATI"
		lbl_nom.position = Vector2(20, 20)
		lbl_nom.add_theme_font_size_override("font_size", 20)
		lbl_nom.add_theme_color_override("font_color", Color(1, 1, 1))
		add_child(lbl_nom)
		_lbl_mati_nombre = lbl_nom

		_barra_mati = ProgressBar.new()
		_barra_mati.position = Vector2(20, 46)
		_barra_mati.size     = Vector2(260, 20)
		_barra_mati.max_value = 100
		_barra_mati.value     = 100
		_barra_mati.show_percentage = false
		var sty_m := StyleBoxFlat.new()
		sty_m.bg_color = Color(0.15, 0.80, 0.25)
		sty_m.corner_radius_top_left = 6; sty_m.corner_radius_top_right = 6
		sty_m.corner_radius_bottom_left = 6; sty_m.corner_radius_bottom_right = 6
		_barra_mati.add_theme_stylebox_override("fill", sty_m)
		_barra_mati.add_theme_stylebox_override("background", sty_bg)
		add_child(_barra_mati)

		# (sin barra de energía)

	else:
		img.position = Vector2(950, 80)
		img.size     = Vector2(290, 370)
		img.modulate = Color(1, 1, 1, 0)  # jefe_entrada lo hace aparecer
		add_child(img)
		_img_jefe = img

		var ruta_j : String = _config.get("jefe_textura", "res://assets/npcs/Jefe hongo.PNG")
		if ruta_j == "":
			ruta_j = "res://assets/npcs/Jefe hongo.PNG"
		if ResourceLoader.exists(ruta_j):
			img.texture = load(ruta_j)

		# Barra vida Jefe — esquina superior derecha
		var lbl_nom := Label.new()
		lbl_nom.text = _config.get("jefe_nombre", "Jefe").to_upper()
		lbl_nom.position = Vector2(960, 20)
		lbl_nom.size     = Vector2(300, 28)
		lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_nom.add_theme_font_size_override("font_size", 20)
		lbl_nom.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		add_child(lbl_nom)
		_lbl_jefe_nombre = lbl_nom

		_barra_jefe = ProgressBar.new()
		_barra_jefe.position = Vector2(960, 46)
		_barra_jefe.size     = Vector2(300, 20)
		_barra_jefe.max_value = 100
		_barra_jefe.value     = 100
		_barra_jefe.show_percentage = false
		var sty_j := StyleBoxFlat.new()
		sty_j.bg_color = Color(0.80, 0.15, 0.15)
		sty_j.corner_radius_top_left = 6; sty_j.corner_radius_top_right = 6
		sty_j.corner_radius_bottom_left = 6; sty_j.corner_radius_bottom_right = 6
		_barra_jefe.add_theme_stylebox_override("fill", sty_j)
		_barra_jefe.add_theme_stylebox_override("background", sty_bg)
		add_child(_barra_jefe)

func _construir_zona_math() -> void:
	# Operación matemática — arriba al centro
	_lbl_operacion = Label.new()
	_lbl_operacion.position = Vector2(0, 10)
	_lbl_operacion.size     = Vector2(1280, 60)
	_lbl_operacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_operacion.add_theme_font_size_override("font_size", 52)
	_lbl_operacion.add_theme_color_override("font_color", Color(1, 1, 1))
	_lbl_operacion.text = "?"
	add_child(_lbl_operacion)

	# Label feedback
	_lbl_feedback = Label.new()
	_lbl_feedback.position = Vector2(0, 395)
	_lbl_feedback.size     = Vector2(1280, 40)
	_lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_feedback.add_theme_font_size_override("font_size", 26)
	_lbl_feedback.add_theme_color_override("font_color", Color(1, 1, 0.3))
	_lbl_feedback.visible = false
	add_child(_lbl_feedback)

# ─────────────────────────────────────────────────────────────
#  ESTRELLAS FLOTANTES — opciones con flechas
# ─────────────────────────────────────────────────────────────
func _crear_opciones_estrellas() -> void:
	for n in _opciones_nodos:
		if is_instance_valid(n):
			n.queue_free()
	_opciones_nodos.clear()
	_alturas_opciones.clear()

	var tex_estrella = null
	const RUTAS_ESTRELLA := [
		"res://assets/ui/Estrella Amarilla.PNG",
		"res://assets/ui/estrella_respuesta.png",
	]
	for ruta in RUTAS_ESTRELLA:
		if ResourceLoader.exists(ruta):
			tex_estrella = load(ruta)
			break

	# 4 estrellas verticales, centradas, bien por debajo de la ecuación (y≥90)
	const W      : float = 160.0
	const H      : float = 130.0
	const GAP    : float = 12.0
	const STAR_X : float = (1280.0 - W) / 2.0
	const TOP_MIN: float = 90.0   # nunca sobre la ecuación (y=0–70)
	var total_h  : float = TOTAL_OPCIONES * H + (TOTAL_OPCIONES - 1) * GAP
	# Centrar en la zona 90–700 de la pantalla
	var zona_h   : float = 700.0 - TOP_MIN
	var start_y  : float = TOP_MIN + (zona_h - total_h) / 2.0

	for i in TOTAL_OPCIONES:
		var contenedor := Control.new()
		contenedor.position    = Vector2(STAR_X, start_y + i * (H + GAP))
		contenedor.size        = Vector2(W, H)
		contenedor.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(contenedor)

		if tex_estrella:
			var img := TextureRect.new()
			img.texture      = tex_estrella
			img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
			img.set_anchors_preset(Control.PRESET_FULL_RECT)
			img.mouse_filter = Control.MOUSE_FILTER_IGNORE
			contenedor.add_child(img)

		var lbl := Label.new()
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.text = "?"
		contenedor.add_child(lbl)

		# Clic con mouse
		var idx_captura := i
		contenedor.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_seleccion_actual = idx_captura
				_actualizar_seleccion_visual()
				_confirmar_seleccion()
		)

		_opciones_nodos.append(contenedor)
		_alturas_opciones.append(start_y + i * (H + GAP) + H / 2.0)

	_seleccion_actual = 0
	_actualizar_seleccion_visual()

func _actualizar_seleccion_visual() -> void:
	for i in _opciones_nodos.size():
		var c := _opciones_nodos[i] as Control
		if i == _seleccion_actual:
			c.modulate = Color(1.4, 1.4, 0.3)
			c.scale    = Vector2(1.2, 1.2)
		else:
			c.modulate = Color(1, 1, 1)
			c.scale    = Vector2(1.0, 1.0)

func _process(_delta: float) -> void:
	if _turno_bloqueado or _opciones_nodos.is_empty():
		return
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up"):
		_seleccion_actual = max(0, _seleccion_actual - 1)
		_actualizar_seleccion_visual()
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_down"):
		_seleccion_actual = min(TOTAL_OPCIONES - 1, _seleccion_actual + 1)
		_actualizar_seleccion_visual()
	elif Input.is_action_just_pressed("ui_accept"):
		_confirmar_seleccion()

func _confirmar_seleccion() -> void:
	if _turno_bloqueado or _opciones_nodos.is_empty():
		return
	_on_respuesta(_seleccion_actual)

# ─────────────────────────────────────────────────────────────
#  BOLA VERDE — temporizador visual del jefe
# ─────────────────────────────────────────────────────────────
func _lanzar_bola_jefe() -> void:
	_cancelar_bola_jefe()

	# Panel redondo (Panel soporta StyleBoxFlat con esquinas redondeadas)
	var bola := Panel.new()
	bola.size         = Vector2(38, 38)
	bola.position     = Vector2(1000.0, 250.0)
	bola.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.05, 0.85, 0.15)
	# Radio = mitad del tamaño → círculo perfecto
	sty.corner_radius_top_left     = 19
	sty.corner_radius_top_right    = 19
	sty.corner_radius_bottom_left  = 19
	sty.corner_radius_bottom_right = 19
	# Borde brillante efecto bola de mago
	sty.border_width_top    = 3
	sty.border_width_bottom = 3
	sty.border_width_left   = 3
	sty.border_width_right  = 3
	sty.border_color        = Color(0.6, 1.0, 0.3)
	# Resplandor interno
	sty.shadow_color  = Color(0.2, 1.0, 0.3, 0.6)
	sty.shadow_size   = 8
	sty.shadow_offset = Vector2(0, 0)
	bola.add_theme_stylebox_override("panel", sty)

	add_child(bola)
	_bola_jefe = bola

	# La bola tarda 4 segundos en llegar a Mati (un poco más rápido)
	var dest_x : float = 170.0
	var dest_y : float = 250.0
	_tween_bola = create_tween()
	_tween_bola.tween_property(bola, "position", Vector2(dest_x, dest_y), 3.2)\
		.set_trans(Tween.TRANS_LINEAR)
	_tween_bola.tween_callback(_bola_llego_a_mati)

func _cancelar_bola_jefe() -> void:
	if _tween_bola != null and is_instance_valid(_tween_bola):
		_tween_bola.kill()
		_tween_bola = null
	if _bola_jefe != null and is_instance_valid(_bola_jefe):
		_bola_jefe.queue_free()
		_bola_jefe = null

func _bola_llego_a_mati() -> void:
	# La bola llegó → Mati recibe daño y se lanza nueva pregunta
	_cancelar_bola_jefe()
	if _turno_bloqueado:
		return
	_turno_bloqueado = true
	_feedback("¡Te dio la bola!", Color(1.0, 0.4, 0.2))
	if _img_jefe:
		_animador.jefe_ataca(_img_jefe, -1.0)
	await get_tree().create_timer(0.2).timeout
	_dañar_mati()
	await get_tree().create_timer(0.4).timeout
	_turno_bloqueado = false
	if _vida_mati <= 0:
		_derrota()
		return
	_nueva_pregunta()

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

	# Actualizar textos de las estrellas flotantes
	_crear_opciones_estrellas()
	for i in _opciones_nodos.size():
		var c := _opciones_nodos[i] as Control
		# El Label es el último hijo
		var lbl := c.get_child(c.get_child_count() - 1) as Label
		if lbl:
			lbl.text = str(opciones[i])
	_seleccion_actual = 0
	_actualizar_seleccion_visual()

	# Jefe lanza bola — el tiempo de viaje es el tiempo para contestar
	_lanzar_bola_jefe()

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

	# El jugador respondió — cancelar bola en vuelo
	_cancelar_bola_jefe()

	# Deshabilitar visualmente las estrellas durante la respuesta
	for n in _opciones_nodos:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var val_elegido: int = int(_botones_vals[idx])
	var correcto: bool = val_elegido == _respuesta_ok
	_pregs_respondidas += 1

	if correcto:
		_aciertos += 1
		# Resaltar estrella correcta en verde
		if idx < _opciones_nodos.size():
			(_opciones_nodos[idx] as Control).modulate = Color(0.3, 1.2, 0.3)
		_feedback("¡Correcto!", Color(0.3, 1.0, 0.4))
		if _efectos:
			_efectos.flash_correcto(get_tree().root)
		MusicaManager.play_sfx("correcto")
		await get_tree().create_timer(0.35).timeout

		if _img_mati:
			_animador.interaccion(_img_mati)
		await get_tree().create_timer(0.3).timeout

		_dañar_jefe(1)
	else:
		# Resaltar estrella incorrecta en rojo
		if idx < _opciones_nodos.size():
			(_opciones_nodos[idx] as Control).modulate = Color(1.2, 0.3, 0.3)
		_feedback("¡Incorrecto!", Color(1.0, 0.3, 0.3))
		if _efectos:
			_efectos.flash_incorrecto(get_tree().root)
			_efectos.sacudida(self, 4.0, 0.25)
		await get_tree().create_timer(0.35).timeout

		if _img_mati:
			_animador.error_respuesta(_img_mati)
		await get_tree().create_timer(0.3).timeout

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
	_cancelar_bola_jefe()
	_lbl_operacion.text = ""
	for n in _opciones_nodos:
		if is_instance_valid(n):
			(n as Control).visible = false

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

	var datos: Dictionary = _guardado.cargar()
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
	_cancelar_bola_jefe()
	for n in _opciones_nodos:
		if is_instance_valid(n):
			(n as Control).visible = false

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

func _colorear_btn(_idx: int, _color: Color) -> void:
	pass  # ya no se usa con el sistema de estrellas

func _restablecer_color_btn(_idx: int) -> void:
	pass  # ya no se usa con el sistema de estrellas

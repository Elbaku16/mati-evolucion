extends Control

# ═══════════════════════════════════════════════════════════════
#  MINIJUEGO MEMORIA ESPACIAL — Dispositivo alienígena
#
#  Mecánica Simon Says: el dispositivo muestra una secuencia de
#  luces de colores; el jugador repite la secuencia en orden.
#
#  Configuración (user://memoria_config.json):
#    {
#      "titulo":       "Dispositivo Alienígena",
#      "nivel_inicio": 2,          # longitud inicial de secuencia
#      "rondas":       5,          # cuántas rondas antes de victoria
#      "monedas":      10,
#      "seccion_id":   200,
#      "escena_origen":"res://scenes/Mapa.tscn"
#    }
#
#  Llamada:
#    MinijuegoMemoria.guardar_config({...})
#    TransitionManager.cambiar_escena("res://scenes/MinijuegoMemoria.tscn")
# ═══════════════════════════════════════════════════════════════

const COLORES_BTN := [
	Color(0.10, 0.60, 1.00),   # azul
	Color(0.90, 0.25, 0.20),   # rojo
	Color(0.15, 0.85, 0.30),   # verde
	Color(1.00, 0.85, 0.10),   # amarillo
]
const COLORES_BRILLO := [
	Color(0.50, 0.85, 1.00),
	Color(1.00, 0.60, 0.55),
	Color(0.55, 1.00, 0.65),
	Color(1.00, 1.00, 0.55),
]
const NOMBRES_BTN := ["Azul", "Rojo", "Verde", "Amarillo"]
const SFX_NOTAS  := ["correcto", "moneda", "fanfare", "click"]   # mapeo a SFX existentes

static func guardar_config(cfg: Dictionary) -> void:
	const TEMP := "user://memoria_config.json"
	var f := FileAccess.open(TEMP, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))
		f.close()

func _leer_config() -> Dictionary:
	var defaults := {
		"titulo":        "Dispositivo Alienígena",
		"nivel_inicio":  2,
		"rondas":        5,
		"monedas":       10,
		"seccion_id":    0,
		"escena_origen": "res://scenes/Mapa.tscn"
	}
	const TEMP := "user://memoria_config.json"
	if FileAccess.file_exists(TEMP):
		var f := FileAccess.open(TEMP, FileAccess.READ)
		if f:
			var j := JSON.new()
			if j.parse(f.get_as_text()) == OK:
				for k in j.data:
					defaults[k] = j.data[k]
			f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	return defaults

# ─────────────────────────────────────────────────────────────
#  ESTADO
# ─────────────────────────────────────────────────────────────
var _config       : Dictionary = {}
var _guardado                   = null
var _efectos                    = null

var _secuencia    : Array  = []
var _longitud     : int    = 2
var _ronda_actual : int    = 0
var _rondas_max   : int    = 5
var _indice_input : int    = 0
var _etapa        : String = "intro"   # intro | mostrando | input | victoria | derrota | esperando

var _botones      : Array  = []
var _brillo_activo : int   = -1   # índice del botón iluminado (-1 = ninguno)

# UI
var _lbl_titulo   : Label      = null
var _lbl_ronda    : Label      = null
var _lbl_feedback : Label      = null
var _lbl_instruc  : Label      = null
var _tiempo_ui    : float      = 0.0

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_guardado = load("res://scripts/guardado.gd").new()
	_efectos  = load("res://scripts/efectos_ui.gd")
	_config   = _leer_config()

	_longitud   = int(_config.get("nivel_inicio", 2))
	_rondas_max = int(_config.get("rondas", 5))

	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir_ui()
	_mostrar_intro()

# ─────────────────────────────────────────────────────────────
#  CONSTRUCCIÓN DE UI
# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	# Fondo espacial
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Estrellas decorativas (puntos estáticos)
	var strs := Node2D.new()
	strs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(strs)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Dispositivo alienígena — cuerpo central
	var dispositivo := Panel.new()
	dispositivo.position = Vector2(290, 60)
	dispositivo.size     = Vector2(700, 580)
	var sty_d := StyleBoxFlat.new()
	sty_d.bg_color = Color(0.05, 0.03, 0.14, 0.95)
	sty_d.border_width_left = 3; sty_d.border_width_right  = 3
	sty_d.border_width_top  = 3; sty_d.border_width_bottom = 3
	sty_d.border_color = Color(0.4, 0.8, 1.0, 0.8)
	sty_d.corner_radius_top_left    = 24; sty_d.corner_radius_top_right    = 24
	sty_d.corner_radius_bottom_left = 24; sty_d.corner_radius_bottom_right = 24
	dispositivo.add_theme_stylebox_override("panel", sty_d)
	add_child(dispositivo)

	# Título
	_lbl_titulo = Label.new()
	_lbl_titulo.text = _config.get("titulo", "Dispositivo Alienígena")
	_lbl_titulo.position = Vector2(0, 18)
	_lbl_titulo.size     = Vector2(700, 42)
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.add_theme_font_size_override("font_size", 28)
	_lbl_titulo.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	dispositivo.add_child(_lbl_titulo)

	# Indicador de ronda
	_lbl_ronda = Label.new()
	_lbl_ronda.text = "Ronda 0 / %d" % _rondas_max
	_lbl_ronda.position = Vector2(0, 58)
	_lbl_ronda.size     = Vector2(700, 32)
	_lbl_ronda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_ronda.add_theme_font_size_override("font_size", 20)
	_lbl_ronda.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	dispositivo.add_child(_lbl_ronda)

	# 4 botones grandes en cuadrícula 2×2
	var btn_size  : float = 200.0
	var btn_gap   : float = 20.0
	var grid_w    : float = btn_size * 2 + btn_gap
	var grid_h    : float = btn_size * 2 + btn_gap
	var start_x   : float = (700.0 - grid_w) * 0.5
	var start_y   : float = 100.0

	var posiciones := [
		Vector2(start_x,            start_y),
		Vector2(start_x + btn_size + btn_gap, start_y),
		Vector2(start_x,            start_y + btn_size + btn_gap),
		Vector2(start_x + btn_size + btn_gap, start_y + btn_size + btn_gap),
	]

	for i in 4:
		var btn := _Boton.new()
		btn.idx          = i
		btn.col_base     = COLORES_BTN[i]
		btn.col_brillo   = COLORES_BRILLO[i]
		btn.nombre       = NOMBRES_BTN[i]
		btn.position     = posiciones[i]
		btn.size         = Vector2(btn_size, btn_size)
		btn.pressed.connect(func(): _on_boton_presionado(i))
		btn.disabled     = true
		dispositivo.add_child(btn)
		_botones.append(btn)

	# Instrucción
	_lbl_instruc = Label.new()
	_lbl_instruc.text = "Observa la secuencia..."
	_lbl_instruc.position = Vector2(0, 525)
	_lbl_instruc.size     = Vector2(700, 32)
	_lbl_instruc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_instruc.add_theme_font_size_override("font_size", 20)
	_lbl_instruc.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	dispositivo.add_child(_lbl_instruc)

	# Feedback
	_lbl_feedback = Label.new()
	_lbl_feedback.position = Vector2(0, 495)
	_lbl_feedback.size     = Vector2(700, 30)
	_lbl_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_feedback.add_theme_font_size_override("font_size", 22)
	_lbl_feedback.visible = false
	dispositivo.add_child(_lbl_feedback)

	# Botón volver
	var btn_v := Button.new()
	btn_v.text = "← Salir"
	btn_v.position = Vector2(16, 668)
	btn_v.size     = Vector2(130, 42)
	btn_v.add_theme_font_size_override("font_size", 18)
	btn_v.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)
	add_child(btn_v)

# ─────────────────────────────────────────────────────────────
#  INTRO
# ─────────────────────────────────────────────────────────────
func _mostrar_intro() -> void:
	_etapa = "intro"
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.10, 0.92)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var lbl := Label.new()
	lbl.text = "🛸 Repite la secuencia\nde luces en orden"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
	overlay.add_child(lbl)

	var btn := Button.new()
	btn.text = "▶ Comenzar"
	btn.size = Vector2(220, 60)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	btn.offset_left   = -110
	btn.offset_top    = -100
	btn.offset_right  = 110
	btn.offset_bottom = -40
	btn.add_theme_font_size_override("font_size", 26)
	overlay.add_child(btn)
	btn.pressed.connect(func():
		canvas.queue_free()
		_iniciar_ronda()
	)

# ─────────────────────────────────────────────────────────────
#  LÓGICA DE RONDAS
# ─────────────────────────────────────────────────────────────
func _iniciar_ronda() -> void:
	_ronda_actual += 1
	_secuencia = []
	for _i in _longitud:
		_secuencia.append(randi() % 4)

	if _lbl_ronda:
		_lbl_ronda.text = "Ronda %d / %d" % [_ronda_actual, _rondas_max]
	if _lbl_instruc:
		_lbl_instruc.text = "Observa la secuencia..."
	if _lbl_feedback:
		_lbl_feedback.visible = false

	for btn in _botones:
		btn.disabled = true

	await get_tree().create_timer(0.6).timeout
	_mostrar_secuencia()

func _mostrar_secuencia() -> void:
	_etapa = "mostrando"
	for idx_seq in _secuencia.size():
		var btn_idx : int = _secuencia[idx_seq]
		await get_tree().create_timer(0.25).timeout
		_iluminar_boton(btn_idx, true)
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx(SFX_NOTAS[btn_idx])
		await get_tree().create_timer(0.55).timeout
		_iluminar_boton(btn_idx, false)

	await get_tree().create_timer(0.3).timeout
	_iniciar_input()

func _iniciar_input() -> void:
	_etapa        = "input"
	_indice_input = 0
	for btn in _botones:
		btn.disabled = false
	if _lbl_instruc:
		_lbl_instruc.text = "¡Tu turno! Repite la secuencia"

func _iluminar_boton(idx: int, encender: bool) -> void:
	if idx < 0 or idx >= _botones.size():
		return
	_botones[idx].encendido = encender
	_botones[idx].queue_redraw()

# ─────────────────────────────────────────────────────────────
#  INPUT DEL JUGADOR
# ─────────────────────────────────────────────────────────────
func _on_boton_presionado(idx: int) -> void:
	if _etapa != "input":
		return

	# Efecto visual inmediato
	_iluminar_boton(idx, true)
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx(SFX_NOTAS[idx])
	await get_tree().create_timer(0.22).timeout
	_iluminar_boton(idx, false)

	var esperado : int = _secuencia[_indice_input]

	if idx == esperado:
		_indice_input += 1
		if _indice_input >= _secuencia.size():
			# Ronda completada
			await get_tree().create_timer(0.2).timeout
			_on_ronda_ok()
	else:
		# Error
		_etapa = "esperando"
		for btn in _botones:
			btn.disabled = true
		if _efectos:
			_efectos.flash_incorrecto(get_tree().root)
		if _lbl_feedback:
			_lbl_feedback.text = "✗  Incorrecto — vuelve a intentarlo"
			_lbl_feedback.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
			_lbl_feedback.visible = true
		await get_tree().create_timer(1.5).timeout
		# Repetir la misma ronda (no aumenta longitud)
		_ronda_actual -= 1
		_iniciar_ronda()

func _on_ronda_ok() -> void:
	for btn in _botones:
		btn.disabled = true
	if _efectos:
		_efectos.flash_correcto(get_tree().root)
	if _lbl_feedback:
		_lbl_feedback.text = "✓  ¡Excelente!"
		_lbl_feedback.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		_lbl_feedback.visible = true

	await get_tree().create_timer(0.8).timeout

	if _ronda_actual >= _rondas_max:
		_victoria()
	else:
		# Aumentar longitud cada 2 rondas
		if _ronda_actual % 2 == 0:
			_longitud += 1
		_iniciar_ronda()

# ─────────────────────────────────────────────────────────────
#  VICTORIA
# ─────────────────────────────────────────────────────────────
func _victoria() -> void:
	_etapa = "victoria"
	var monedas : int = int(_config.get("monedas", 10))
	var sec_id  : int = int(_config.get("seccion_id", 0))

	# Guardar progreso y monedas
	var datos := _guardado.cargar()
	if sec_id > 0:
		var secs : Array = datos.get("secciones", [])
		if not sec_id in secs:
			secs.append(sec_id)
		datos["secciones"] = secs
	datos["monedas"] = int(datos.get("monedas", 0)) + monedas
	datos["estrellas"] = int(datos.get("estrellas", 0)) + 1
	var sid_m := int(_config.get("seccion_id", 0))
	if sid_m == 120: load("res://scripts/misiones.gd").marcar_completa("p2_memoria", datos)
	var archivo := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

	if _efectos:
		_efectos.flash_dorado(get_tree().root)
		_efectos.estrella_burst(get_tree().root, Vector2(640, 360), 10)
	var cel_script = load("res://scripts/celebracion.gd")
	if cel_script:
		cel_script.lanzar(get_tree().root)

	# Panel de victoria
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.05, 0.02, 0.88)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var lbl := Label.new()
	lbl.text = "🌟 ¡Memoria activada!\n+%d 🪙   +⭐" % monedas
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	overlay.add_child(lbl)

	var btn := Button.new()
	btn.text = "Continuar ▶"
	btn.size = Vector2(240, 60)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	btn.offset_left   = -120
	btn.offset_top    = -100
	btn.offset_right  = 120
	btn.offset_bottom = -40
	btn.add_theme_font_size_override("font_size", 26)
	overlay.add_child(btn)
	btn.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)

# ─────────────────────────────────────────────────────────────
#  BOTÓN ALIENÍGENA — clase interna con dibujo propio
# ─────────────────────────────────────────────────────────────
class _Boton extends Button:
	var idx        : int   = 0
	var col_base   : Color = Color(0.3, 0.3, 0.8)
	var col_brillo : Color = Color(0.6, 0.6, 1.0)
	var nombre     : String = ""
	var encendido  : bool  = false
	var _tiempo    : float = 0.0

	func _ready() -> void:
		flat = true
		add_theme_color_override("font_color", Color.WHITE)

	func _process(delta: float) -> void:
		_tiempo += delta
		if encendido:
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var r := min(w, h) * 0.5 - 8.0
		var centro := Vector2(w * 0.5, h * 0.5)

		var col : Color = col_brillo if encendido else col_base
		if disabled and not encendido:
			col = col_base.lerp(Color(0.2, 0.2, 0.2), 0.5)

		# Sombra
		draw_circle(centro + Vector2(4, 4), r, Color(0, 0, 0, 0.35))
		# Círculo principal
		draw_circle(centro, r, col)
		# Borde
		draw_arc(centro, r, 0.0, TAU, 48, col.lightened(0.4), 3.0)

		if encendido:
			# Halo pulsante
			var pulso := 0.3 + 0.3 * sin(_tiempo * 10.0)
			draw_arc(centro, r + 8.0, 0.0, TAU, 48,
			         Color(col.r, col.g, col.b, pulso), 6.0)
			# Reflejo interior
			draw_circle(centro - Vector2(r * 0.25, r * 0.25), r * 0.22,
			            Color(1, 1, 1, 0.35))

		# Nombre del color (texto)
		# (Los Labels de Godot no se dibujan en _draw — el texto viene del Button.text,
		# que configuramos invisible y usamos el _draw para el diseño)

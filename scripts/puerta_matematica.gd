extends Node2D

# ═══════════════════════════════════════════════════════════════
#  PUERTA MATEMÁTICA — mecanismo interactivo in-world
#
#  Uso (desde _crear_npcs o _ready de un mundo):
#    var puerta = load("res://scripts/puerta_matematica.gd").new()
#    puerta.configurar({
#        "tema":      "mundo1",   # "mundo1" | "mundo2" | "mundo3"
#        "tipo":      "auto",     # "suma"|"resta"|"multiplicacion"|"faltante"|"secuencia"|"simbolo"
#        "nivel":     2,          # 1-3
#        "tipo_visual":"puerta",  # "puerta" | "cofre" | "palanca"
#        "monedas":   5,
#        "id":        101,        # ID único de guardado (0 = sin guardar)
#    })
#    puerta.position = Vector2(400, 300)
#    add_child(puerta)
#    # Señal: puerta.abierta_signal.connect(mi_callback)
# ═══════════════════════════════════════════════════════════════

signal abierta_signal(id: int)

# ─────────────────────────────────────────────────────────────
#  TEMAS VISUALES POR PLANETA
# ─────────────────────────────────────────────────────────────
const TEMAS := {
	"mundo1": {
		"color_cuerpo":  Color(0.08, 0.28, 0.10),
		"color_borde":   Color(0.30, 0.90, 0.35),
		"color_runa":    Color(0.50, 1.00, 0.55),
		"color_panel":   Color(0.05, 0.18, 0.07, 0.95),
		"color_btn":     Color(0.12, 0.50, 0.15),
		"color_hover":   Color(0.18, 0.70, 0.22),
		"nombre":        "Puerta del Bosque",
	},
	"mundo2": {
		"color_cuerpo":  Color(0.05, 0.10, 0.30),
		"color_borde":   Color(0.30, 0.65, 1.00),
		"color_runa":    Color(0.55, 0.85, 1.00),
		"color_panel":   Color(0.03, 0.07, 0.22, 0.95),
		"color_btn":     Color(0.10, 0.25, 0.60),
		"color_hover":   Color(0.15, 0.40, 0.85),
		"nombre":        "Compuerta de Hielo",
	},
	"mundo3": {
		"color_cuerpo":  Color(0.22, 0.05, 0.28),
		"color_borde":   Color(0.80, 0.30, 1.00),
		"color_runa":    Color(0.95, 0.60, 1.00),
		"color_panel":   Color(0.14, 0.03, 0.18, 0.95),
		"color_btn":     Color(0.45, 0.10, 0.60),
		"color_hover":   Color(0.65, 0.18, 0.85),
		"nombre":        "Hongo Guardián",
	},
}

const RADIO_INTERACCION : float = 100.0
const ANCHO_PUERTA      : float = 72.0
const ALTO_PUERTA       : float = 100.0

# ─────────────────────────────────────────────────────────────
var _tema_id    : String = "mundo1"
var _tipo       : String = "auto"
var _nivel      : int   = 2
var _visual     : String = "puerta"   # puerta | cofre | palanca
var _monedas    : int   = 5
var _id         : int   = 0

var _abierta       : bool = false
var _resolviendo   : bool = false
var _tiempo_runa   : float = 0.0
var _mati_cerca    : bool = false
var _btn_interactuar : Button = null

var _acertijo      : Dictionary = {}
var _panel_canvas  : CanvasLayer = null
var _guardado      = null
var _efectos       = null

# ─────────────────────────────────────────────────────────────
func configurar(cfg: Dictionary) -> void:
	_tema_id  = cfg.get("tema",    "mundo1")
	_tipo     = cfg.get("tipo",    "auto")
	_nivel    = int(cfg.get("nivel", 2))
	_visual   = cfg.get("tipo_visual", "puerta")
	_monedas  = int(cfg.get("monedas", 5))
	_id       = int(cfg.get("id", 0))

func _ready() -> void:
	_guardado = load("res://scripts/guardado.gd").new()
	_efectos  = load("res://scripts/efectos_ui.gd")

	# Si ya fue abierta en esta sesión, comenzar abierta
	if _id > 0 and _guardado.seccion_completada(_id):
		_abierta = true

	_crear_btn_interactuar()

func _proceso_acertijo_tipo() -> String:
	if _tipo != "auto":
		return _tipo
	var tipos := ["suma", "resta", "multiplicacion", "faltante", "secuencia", "simbolo"]
	return tipos[randi() % tipos.size()]

# ─────────────────────────────────────────────────────────────
#  DIBUJO DE LA PUERTA
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	_tiempo_runa += delta
	queue_redraw()

	# Detectar proximidad de Mati
	var mati := _buscar_mati()
	if mati:
		var dist := position.distance_to(mati.position)
		var cerca := dist < RADIO_INTERACCION and not _abierta
		if cerca != _mati_cerca:
			_mati_cerca = cerca
			if _btn_interactuar:
				_btn_interactuar.visible = cerca

func _draw() -> void:
	var t  := TEMAS.get(_tema_id, TEMAS["mundo1"])
	var cb := t["color_cuerpo"] as Color
	var ce := t["color_borde"]  as Color
	var cr := t["color_runa"]   as Color

	var w : float = ANCHO_PUERTA
	var h : float = ALTO_PUERTA

	if _abierta:
		# Puerta abierta: más brillante, desplazada
		cb = cb.lerp(Color.WHITE, 0.3)
		ce = ce.lerp(Color.WHITE, 0.5)

	match _visual:
		"puerta":
			_draw_puerta(w, h, cb, ce, cr)
		"cofre":
			_draw_cofre(w, h * 0.75, cb, ce, cr)
		"palanca":
			_draw_palanca(w * 0.5, h, cb, ce, cr)

func _draw_puerta(w: float, h: float, cb: Color, ce: Color, cr: Color) -> void:
	var rect := Rect2(-w * 0.5, -h, w, h)
	# Sombra
	draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size), Color(0, 0, 0, 0.4))
	# Cuerpo
	draw_rect(rect, cb)
	# Borde
	draw_rect(rect, ce, false, 3.0)
	# Arco superior
	draw_arc(Vector2(0, -h), w * 0.5, PI, TAU, 20, ce, 3.0)

	if _abierta:
		# Destello de apertura
		draw_rect(rect, Color(cr.r, cr.g, cr.b, 0.3))
		return

	# Runa central pulsante
	var pulso := 0.6 + 0.4 * sin(_tiempo_runa * 2.5)
	var rc    := Color(cr.r, cr.g, cr.b, pulso)
	draw_circle(Vector2(0, -h * 0.5), 10.0, rc)
	# Cruz de runa
	draw_line(Vector2(-8, -h * 0.5), Vector2(8, -h * 0.5), rc, 2.5)
	draw_line(Vector2(0, -h * 0.5 - 8), Vector2(0, -h * 0.5 + 8), rc, 2.5)

	# Cerradura
	draw_circle(Vector2(0, -h * 0.35), 6.0, ce)
	draw_circle(Vector2(0, -h * 0.35), 4.0, cb)

func _draw_cofre(w: float, h: float, cb: Color, ce: Color, cr: Color) -> void:
	# Base
	draw_rect(Rect2(-w * 0.5, -h * 0.55, w, h * 0.55), cb)
	draw_rect(Rect2(-w * 0.5, -h * 0.55, w, h * 0.55), ce, false, 2.5)
	# Tapa
	draw_rect(Rect2(-w * 0.5, -h, w, h * 0.45), cb.lerp(Color.WHITE, 0.1))
	draw_rect(Rect2(-w * 0.5, -h, w, h * 0.45), ce, false, 2.5)
	# Bisagra
	draw_rect(Rect2(-6, -h * 0.55 - 4, 12, 8), ce)
	# Cerradura pulsante
	var pulso := 0.5 + 0.5 * sin(_tiempo_runa * 2.0)
	draw_circle(Vector2(0, -h * 0.4), 7.0, Color(cr.r, cr.g, cr.b, pulso) if not _abierta else cr)

func _draw_palanca(w: float, h: float, cb: Color, ce: Color, cr: Color) -> void:
	# Base cuadrada
	draw_rect(Rect2(-w * 0.5, -12, w, 20), cb)
	draw_rect(Rect2(-w * 0.5, -12, w, 20), ce, false, 2.0)
	# Palo
	var angulo := -PI * 0.6 if not _abierta else -PI * 0.25
	var extremo := Vector2(sin(angulo), cos(angulo)) * h * 0.65
	draw_line(Vector2.ZERO, extremo, ce, 6.0)
	# Bola
	var pulso := 0.6 + 0.4 * sin(_tiempo_runa * 3.0)
	draw_circle(extremo, 10.0, Color(cr.r, cr.g, cr.b, pulso) if not _abierta else cr)

# ─────────────────────────────────────────────────────────────
#  BOTÓN INTERACTUAR
# ─────────────────────────────────────────────────────────────
func _crear_btn_interactuar() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 60
	add_child(canvas)

	_btn_interactuar = Button.new()
	_btn_interactuar.text  = "❓ Resolver"
	_btn_interactuar.size  = Vector2(140, 42)
	_btn_interactuar.visible = false
	_btn_interactuar.add_theme_font_size_override("font_size", 16)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.15, 0.08, 0.30, 0.9)
	sty.corner_radius_top_left    = 10; sty.corner_radius_top_right    = 10
	sty.corner_radius_bottom_left = 10; sty.corner_radius_bottom_right = 10
	_btn_interactuar.add_theme_stylebox_override("normal", sty)
	_btn_interactuar.add_theme_stylebox_override("hover",  sty)
	_btn_interactuar.pressed.connect(_activar)
	canvas.add_child(_btn_interactuar)

	# Actualizar posición cada frame vía _process
	set_process(true)

func _process_btn_pos() -> void:
	if _btn_interactuar == null:
		return
	# Convertir posición world a screen
	var vp := get_viewport()
	if vp == null:
		return
	var cam := vp.get_camera_2d()
	var pos_screen : Vector2
	if cam:
		pos_screen = (position - cam.get_screen_center_position()) + \
		             Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
		                     ProjectSettings.get_setting("display/window/size/viewport_height")) * 0.5
	else:
		pos_screen = position
	_btn_interactuar.position = pos_screen + Vector2(-70, -ALTO_PUERTA - 55)

func _process(delta: float) -> void:
	_tiempo_runa += delta
	queue_redraw()
	_process_btn_pos()

	var mati := _buscar_mati()
	if mati:
		var dist := position.distance_to(mati.position)
		var cerca := dist < RADIO_INTERACCION and not _abierta
		if cerca != _mati_cerca:
			_mati_cerca = cerca
			if _btn_interactuar:
				_btn_interactuar.visible = cerca

func _buscar_mati() -> Node2D:
	var raiz := get_tree().get_root()
	# Intentar nodo llamado "Mati" o "mati" en la escena actual
	var escena := get_tree().current_scene
	if escena:
		var m := escena.get_node_or_null("Mati")
		if m == null:
			m = escena.get_node_or_null("mati")
		return m
	return null

# ─────────────────────────────────────────────────────────────
#  ACTIVAR ACERTIJO
# ─────────────────────────────────────────────────────────────
func _activar() -> void:
	if _abierta or _resolviendo:
		return
	_resolviendo = true
	_btn_interactuar.visible = false
	_acertijo = _generar_acertijo()
	_mostrar_panel()

func _generar_acertijo() -> Dictionary:
	var tipo := _proceso_acertijo_tipo()
	var rng  := RandomNumberGenerator.new()
	rng.randomize()

	match tipo:
		"suma":
			var a := rng.randi_range(1, 10 + _nivel * 5)
			var b := rng.randi_range(1, 10 + _nivel * 5)
			return {"tipo": "suma", "pregunta": "%d + %d = ?" % [a, b],
			        "respuesta": a + b, "pista": "Suma los dos números"}

		"resta":
			var a := rng.randi_range(5, 15 + _nivel * 5)
			var b := rng.randi_range(1, a)
			return {"tipo": "resta", "pregunta": "%d - %d = ?" % [a, b],
			        "respuesta": a - b, "pista": "Resta el segundo del primero"}

		"multiplicacion":
			var a := rng.randi_range(2, 2 + _nivel * 3)
			var b := rng.randi_range(2, 9)
			return {"tipo": "mult", "pregunta": "%d × %d = ?" % [a, b],
			        "respuesta": a * b, "pista": "Multiplica los dos números"}

		"faltante":
			var b := rng.randi_range(2, 9)
			var r := rng.randi_range(2, 9)
			return {"tipo": "faltante", "pregunta": "__ × %d = %d" % [b, r * b],
			        "respuesta": r, "pista": "¿Qué número multiplicado por %d da %d?" % [b, r * b]}

		"secuencia":
			var ini  := rng.randi_range(1, 10)
			var paso := rng.randi_range(2, 2 + _nivel * 2)
			var sig  := ini + paso * 3
			return {"tipo": "secuencia",
			        "pregunta": "%d, %d, %d, __" % [ini, ini + paso, ini + paso * 2],
			        "respuesta": sig,
			        "pista": "El patrón aumenta de %d en %d" % [paso, paso]}

		"simbolo":
			var a := rng.randi_range(2, 9)
			var b := rng.randi_range(1, 9)
			# Elegir operación aleatoria
			var ops := ["+", "-", "×"]
			var op  := ops[rng.randi() % ops.size()]
			var res : int
			match op:
				"+": res = a + b
				"-": res = max(a, b) - min(a, b); if a < b: a = b - 1 + 1
				"×": res = a * b
			return {"tipo": "simbolo", "pregunta": "%d __ %d = %d" % [a, b, res],
			        "respuesta": op,
			        "opciones_simbolo": ["+", "-", "×", "÷"],
			        "pista": "¿Qué operación produce ese resultado?"}

		_:
			var a := rng.randi_range(1, 9)
			var b := rng.randi_range(1, 9)
			return {"tipo": "suma", "pregunta": "%d + %d = ?" % [a, b],
			        "respuesta": a + b, "pista": "Suma los dos números"}

# ─────────────────────────────────────────────────────────────
#  PANEL DE ACERTIJO
# ─────────────────────────────────────────────────────────────
func _mostrar_panel() -> void:
	var t := TEMAS.get(_tema_id, TEMAS["mundo1"])

	_panel_canvas = CanvasLayer.new()
	_panel_canvas.layer = 70
	get_tree().root.add_child(_panel_canvas)

	# Fondo oscuro semitransparente
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.55)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_canvas.add_child(fondo)

	# Panel central
	var panel := Panel.new()
	panel.position = Vector2(290, 160)
	panel.size     = Vector2(700, 380)
	var sty := StyleBoxFlat.new()
	sty.bg_color = t["color_panel"] as Color
	sty.border_width_left = 3; sty.border_width_right  = 3
	sty.border_width_top  = 3; sty.border_width_bottom = 3
	sty.border_color = t["color_borde"] as Color
	sty.corner_radius_top_left    = 20; sty.corner_radius_top_right    = 20
	sty.corner_radius_bottom_left = 20; sty.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", sty)
	_panel_canvas.add_child(panel)

	# Nombre del mecanismo
	var lbl_nom := Label.new()
	lbl_nom.text = t["nombre"] as String
	lbl_nom.position = Vector2(0, 18)
	lbl_nom.size     = Vector2(700, 36)
	lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_nom.add_theme_font_size_override("font_size", 22)
	lbl_nom.add_theme_color_override("font_color", t["color_runa"] as Color)
	panel.add_child(lbl_nom)

	# Pregunta
	var lbl_preg := Label.new()
	lbl_preg.text = _acertijo.get("pregunta", "?")
	lbl_preg.position = Vector2(0, 65)
	lbl_preg.size     = Vector2(700, 60)
	lbl_preg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_preg.add_theme_font_size_override("font_size", 44)
	lbl_preg.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl_preg)

	# Pista (inicialmente oculta)
	var lbl_pista := Label.new()
	lbl_pista.text    = "💡 " + _acertijo.get("pista", "")
	lbl_pista.name    = "LblPista"
	lbl_pista.position = Vector2(10, 136)
	lbl_pista.size     = Vector2(680, 30)
	lbl_pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_pista.add_theme_font_size_override("font_size", 16)
	lbl_pista.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	lbl_pista.visible  = false
	panel.add_child(lbl_pista)

	# Feedback
	var lbl_fb := Label.new()
	lbl_fb.name     = "LblFeedback"
	lbl_fb.position = Vector2(0, 170)
	lbl_fb.size     = Vector2(700, 32)
	lbl_fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_fb.add_theme_font_size_override("font_size", 20)
	panel.add_child(lbl_fb)

	# Botones de respuesta
	var tipo := _acertijo.get("tipo", "suma")
	if tipo == "simbolo":
		_crear_botones_simbolo(panel, t)
	else:
		_crear_botones_numero(panel, t)

	# Botón cerrar (esquina superior derecha)
	var btn_x := Button.new()
	btn_x.text = "✕"
	btn_x.position = Vector2(658, 10)
	btn_x.size     = Vector2(32, 32)
	btn_x.add_theme_font_size_override("font_size", 18)
	btn_x.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	btn_x.pressed.connect(_cerrar_panel)
	panel.add_child(btn_x)

	# Animación de entrada
	panel.scale   = Vector2(0.6, 0.6)
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "scale",       Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(panel, "modulate:a",  1.0,               0.20)

func _crear_botones_numero(panel: Panel, t: Dictionary) -> void:
	var respuesta : int = int(_acertijo.get("respuesta", 0))

	# Generar 4 opciones únicas
	var opciones : Array = [respuesta]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var intentos := 0
	while opciones.size() < 4 and intentos < 40:
		intentos += 1
		var delta_v := rng.randi_range(-8, 8)
		var candidato := respuesta + delta_v
		if candidato != respuesta and candidato >= 0 and not candidato in opciones:
			opciones.append(candidato)
	# Mezclar
	for i in opciones.size():
		var j := rng.randi() % opciones.size()
		var tmp := opciones[i]; opciones[i] = opciones[j]; opciones[j] = tmp

	var btn_w : float = 130.0
	var btn_h : float = 70.0
	var gap   : float = 20.0
	var total_w := opciones.size() * btn_w + (opciones.size() - 1) * gap
	var start_x := (700.0 - total_w) * 0.5

	for i in opciones.size():
		var val : int = opciones[i]
		var btn := Button.new()
		btn.text     = str(val)
		btn.position = Vector2(start_x + i * (btn_w + gap), 220)
		btn.size     = Vector2(btn_w, btn_h)
		btn.add_theme_font_size_override("font_size", 30)
		var sty_b := StyleBoxFlat.new()
		sty_b.bg_color = t["color_btn"] as Color
		sty_b.corner_radius_top_left    = 12; sty_b.corner_radius_top_right    = 12
		sty_b.corner_radius_bottom_left = 12; sty_b.corner_radius_bottom_right = 12
		var sty_h := sty_b.duplicate()
		sty_h.bg_color = t["color_hover"] as Color
		btn.add_theme_stylebox_override("normal", sty_b)
		btn.add_theme_stylebox_override("hover",  sty_h)
		btn.pressed.connect(func(): _evaluar_respuesta(str(val), str(respuesta), panel))
		panel.add_child(btn)

func _crear_botones_simbolo(panel: Panel, t: Dictionary) -> void:
	var opciones : Array = _acertijo.get("opciones_simbolo", ["+", "-", "×", "÷"])
	var respuesta : String = str(_acertijo.get("respuesta", "+"))

	var btn_w : float = 110.0
	var btn_h : float = 70.0
	var gap   : float = 20.0
	var total_w := opciones.size() * btn_w + (opciones.size() - 1) * gap
	var start_x := (700.0 - total_w) * 0.5

	for i in opciones.size():
		var sim : String = opciones[i]
		var btn := Button.new()
		btn.text     = sim
		btn.position = Vector2(start_x + i * (btn_w + gap), 220)
		btn.size     = Vector2(btn_w, btn_h)
		btn.add_theme_font_size_override("font_size", 36)
		var sty_b := StyleBoxFlat.new()
		sty_b.bg_color = t["color_btn"] as Color
		sty_b.corner_radius_top_left    = 12; sty_b.corner_radius_top_right    = 12
		sty_b.corner_radius_bottom_left = 12; sty_b.corner_radius_bottom_right = 12
		var sty_h := sty_b.duplicate()
		sty_h.bg_color = t["color_hover"] as Color
		btn.add_theme_stylebox_override("normal", sty_b)
		btn.add_theme_stylebox_override("hover",  sty_h)
		btn.pressed.connect(func(): _evaluar_respuesta(sim, respuesta, panel))
		panel.add_child(btn)

# ─────────────────────────────────────────────────────────────
#  EVALUAR RESPUESTA
# ─────────────────────────────────────────────────────────────
func _evaluar_respuesta(elegida: String, correcta: String, panel: Panel) -> void:
	var lbl_fb    : Label = panel.get_node_or_null("LblFeedback")
	var lbl_pista : Label = panel.get_node_or_null("LblPista")

	if elegida == correcta:
		if lbl_fb:
			lbl_fb.text = "✓ ¡Correcto!"
			lbl_fb.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx("correcto")
		if _efectos:
			_efectos.flash_correcto(get_tree().root)
		await get_tree().create_timer(0.6).timeout
		_abrir()
	else:
		if lbl_fb:
			lbl_fb.text = "✗ Inténtalo de nuevo"
			lbl_fb.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
			lbl_fb.modulate.a = 0.0
			var tw := create_tween()
			tw.tween_property(lbl_fb, "modulate:a", 1.0, 0.15)
		if lbl_pista:
			lbl_pista.visible = true
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx("incorrecto")
		if _efectos:
			_efectos.flash_incorrecto(get_tree().root)

func _cerrar_panel() -> void:
	if _panel_canvas:
		_panel_canvas.queue_free()
		_panel_canvas = null
	_resolviendo = false
	_btn_interactuar.visible = _mati_cerca

# ─────────────────────────────────────────────────────────────
#  ABRIR
# ─────────────────────────────────────────────────────────────
func _abrir() -> void:
	_abierta = true

	if _panel_canvas:
		_panel_canvas.queue_free()
		_panel_canvas = null
	_resolviendo = false
	if _btn_interactuar:
		_btn_interactuar.visible = false

	# Guardar progreso
	if _id > 0:
		var datos := _guardado.cargar()
		var secs  : Array = datos.get("secciones", [])
		if not _id in secs:
			secs.append(_id)
		datos["secciones"] = secs
		# Dar monedas
		datos["monedas"] = int(datos.get("monedas", 0)) + _monedas
		# Misión de puertas por planeta
		var id_mision := "p1_puertas"
		if _id >= 111 and _id <= 119: id_mision = "p1_puertas"
		elif _id >= 121 and _id <= 129: id_mision = "p2_monedas"
		elif _id >= 121 and _id <= 129: id_mision = "p2_monedas"
		elif _id >= 131 and _id <= 139: id_mision = "p3_acertijos"
		load("res://scripts/misiones.gd").incrementar(id_mision, datos, 1)
		var archivo := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
		if archivo:
			archivo.store_string(JSON.stringify(datos))
			archivo.close()

	# Efectos de apertura
	if _efectos:
		_efectos.estrella_burst(get_tree().root, get_viewport().get_screen_transform() * position)
		if _monedas > 0:
			var pos_scr := get_viewport().get_screen_transform() * position
			_efectos.moneda_flotante(get_tree().root, pos_scr, _monedas)
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx("fanfare")

	queue_redraw()
	abierta_signal.emit(_id)

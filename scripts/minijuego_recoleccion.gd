extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MINIJUEGO RECOLECCIÓN — Mati recolecta objetos en el escenario
#
#  Configuración (via archivo temporal user://minijuego_config.json):
#    {
#      "titulo":          "¡Repara la nave!",
#      "descripcion":     "Recoge 12 cristales energéticos",
#      "objeto_nombre":   "cristal",
#      "objeto_textura":  "res://assets/ui/Estrella Amarilla.PNG",
#      "total":           12,
#      "tiempo":          60,          # segundos (0 = sin límite)
#      "monedas":         8,
#      "seccion_id":      100,         # ID de guardado (0 = no guarda)
#      "escena_origen":   "res://scenes/Mundo1Explorar.tscn",
#      "obstaculos":      true
#    }
#
#  Llamada desde cualquier mundo:
#    MinijuegoRecoleccion.guardar_config({...})
#    TransitionManager.cambiar_escena("res://scenes/MinijuegoRecoleccion.tscn")
# ═══════════════════════════════════════════════════════════════

const VELOCIDAD_MATI   : float = 320.0
const RADIO_RECOLECTAR : float = 55.0
const OBJETO_RADIO     : float = 24.0
const MATI_RADIO       : float = 28.0

const LIMITE_IZQ : float = -800.0
const LIMITE_DER : float =  800.0
const LIMITE_ARR : float =  -300.0
const LIMITE_ABA : float =   300.0

# ─────────────────────────────────────────────────────────────
#  ESTADO
# ─────────────────────────────────────────────────────────────
var _config        : Dictionary = {}
var _guardado                   = null
var _animador                   = null
var _moneda_burst               = null
var _habilidades                = null
var _efectos                    = null

var _velocidad_real  : float = VELOCIDAD_MATI
var _radio_real      : float = RADIO_RECOLECTAR

var _total_obj     : int   = 12
var _recolectados  : int   = 0
var _tiempo_max    : float = 60.0
var _tiempo        : float = 0.0
var _activo        : bool  = false
var _completado    : bool  = false

var _mati          : Node2D = null
var _objetos       : Array  = []
var _obstaculos    : Array  = []

# UI
var _lbl_contador  : Label      = null
var _lbl_tiempo    : Label      = null
var _lbl_titulo    : Label      = null
var _barra_progreso: ProgressBar = null

# Input
var _dir           : Vector2 = Vector2.ZERO

# ─────────────────────────────────────────────────────────────
static func guardar_config(cfg: Dictionary) -> void:
	const TEMP := "user://minijuego_config.json"
	var f := FileAccess.open(TEMP, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))
		f.close()

func _leer_config() -> Dictionary:
	var defaults := {
		"titulo":         "¡Recoge los cristales!",
		"descripcion":    "Recoge los cristales para reparar la nave",
		"objeto_nombre":  "cristal",
		"objeto_textura": "res://assets/ui/Estrella Amarilla.PNG",
		"total":          10,
		"tiempo":         60,
		"monedas":        8,
		"seccion_id":     0,
		"escena_origen":  "res://scenes/Mapa.tscn",
		"obstaculos":     true
	}
	const TEMP := "user://minijuego_config.json"
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
func _ready() -> void:
	_guardado     = load("res://scripts/guardado.gd").new()
	_animador     = load("res://scripts/animador_personaje.gd")
	_moneda_burst = load("res://scripts/moneda_burst.gd")
	_habilidades  = load("res://scripts/habilidades.gd").new()
	_efectos      = load("res://scripts/efectos_ui.gd")
	_config       = _leer_config()

	if _habilidades.esta_activa("turbo"):
		_velocidad_real = VELOCIDAD_MATI * 1.3
	if _habilidades.esta_activa("iman"):
		_radio_real = RADIO_RECOLECTAR * 1.5
	_total_obj   = int(_config.get("total", 10))
	_tiempo_max  = float(_config.get("tiempo", 60))
	_tiempo      = _tiempo_max

	_construir_escenario()
	_construir_ui()
	_mostrar_intro()

# ─────────────────────────────────────────────────────────────
#  ESCENARIO
# ─────────────────────────────────────────────────────────────
func _construir_escenario() -> void:
	# Fondo
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.08, 0.18)
	fondo.position = Vector2(LIMITE_IZQ, LIMITE_ARR)
	fondo.size = Vector2(LIMITE_DER - LIMITE_IZQ, LIMITE_ABA - LIMITE_ARR)
	fondo.z_index = -10
	add_child(fondo)

	# Suelo con líneas de cuadrícula decorativas
	for x in range(int(LIMITE_IZQ), int(LIMITE_DER) + 1, 120):
		var linea := Line2D.new()
		linea.add_point(Vector2(x, LIMITE_ARR))
		linea.add_point(Vector2(x, LIMITE_ABA))
		linea.width = 1.0
		linea.default_color = Color(0.2, 0.3, 0.6, 0.15)
		linea.z_index = -9
		add_child(linea)
	for y in range(int(LIMITE_ARR), int(LIMITE_ABA) + 1, 100):
		var linea := Line2D.new()
		linea.add_point(Vector2(LIMITE_IZQ, y))
		linea.add_point(Vector2(LIMITE_DER, y))
		linea.width = 1.0
		linea.default_color = Color(0.2, 0.3, 0.6, 0.15)
		linea.z_index = -9
		add_child(linea)

	# Mati
	_mati = Node2D.new()
	_mati.name = "Mati"
	add_child(_mati)
	var datos: Dictionary = _guardado.cargar()
	var skin  : String = datos.get("skin_activa", "clasica")
	var rutas := {
		"clasica":  "res://assets/personajes/mati_frente.PNG",
		"ninja":    "res://assets/personajes/mati_ninja.PNG",
		"escolar":  "res://assets/personajes/mati_escolar.PNG",
		"fachero":  "res://assets/personajes/mati_fachero.PNG",
	}
	var ruta_mati := rutas.get(skin, rutas["clasica"])
	var sprite_mati := TextureRect.new()
	sprite_mati.name = "Sprite"
	if ResourceLoader.exists(ruta_mati):
		sprite_mati.texture = load(ruta_mati)
	sprite_mati.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_mati.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	sprite_mati.custom_minimum_size = Vector2(72, 90)
	sprite_mati.position       = Vector2(-36, -90)
	_mati.add_child(sprite_mati)
	_animador.idle(_mati)

	# Obstáculos simples (rocas espaciales)
	if _config.get("obstaculos", true):
		_crear_obstaculos()

	# Objetos a recolectar
	_sembrar_objetos()

func _crear_obstaculos() -> void:
	var posiciones := [
		Vector2(-400, -100), Vector2(300, 150), Vector2(-200, 200),
		Vector2(500, -180),  Vector2(-600, 100), Vector2(100, -220),
	]
	for pos in posiciones:
		var obs := ColorRect.new()
		obs.color   = Color(0.35, 0.28, 0.45)
		obs.size    = Vector2(randf_range(60, 110), randf_range(50, 80))
		obs.position = pos - obs.size * 0.5
		obs.z_index = 1
		add_child(obs)
		# Borde
		var borde := ColorRect.new()
		borde.color  = Color(0.55, 0.42, 0.75, 0.6)
		borde.size   = obs.size + Vector2(4, 4)
		borde.position = obs.position - Vector2(2, 2)
		borde.z_index = 0
		add_child(borde)
		_obstaculos.append({"rect": obs, "size": obs.size, "pos": pos})

func _sembrar_objetos() -> void:
	var ruta_tex : String = _config.get("objeto_textura", "res://assets/ui/Estrella Amarilla.PNG")
	var tex : Texture2D = null
	if ResourceLoader.exists(ruta_tex):
		tex = load(ruta_tex)

	# Colores alternos para identificar los objetos
	var colores := [Color(1,0.9,0.1), Color(0.3,0.9,1), Color(1,0.5,0.1), Color(0.5,1,0.4)]
	var intentos := 0

	for i in _total_obj:
		var pos := _posicion_valida()
		var obj := Node2D.new()
		obj.position = pos
		obj.z_index  = 2
		add_child(obj)

		var tr := TextureRect.new()
		if tex:
			tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.custom_minimum_size = Vector2(44, 44)
		tr.position = Vector2(-22, -22)
		tr.modulate = colores[i % colores.size()]
		obj.add_child(tr)

		# Brillo / aura
		var aura := ColorRect.new()
		aura.color    = Color(1, 1, 0.5, 0.18)
		aura.size     = Vector2(54, 54)
		aura.position = Vector2(-27, -27)
		aura.z_index  = -1
		obj.add_child(aura)

		# Animación idle flotante
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(obj, "position:y", pos.y - 8, 0.8 + randf() * 0.4)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_property(obj, "position:y", pos.y, 0.8 + randf() * 0.4)\
			.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

		_objetos.append({"node": obj, "pos": pos, "activo": true})

func _posicion_valida() -> Vector2:
	var margen := 60.0
	for _i in 40:
		var x := randf_range(LIMITE_IZQ + margen, LIMITE_DER - margen)
		var y := randf_range(LIMITE_ARR + margen, LIMITE_ABA - margen)
		var p := Vector2(x, y)
		# No demasiado cerca del centro (donde empieza Mati)
		if p.distance_to(Vector2.ZERO) < 100:
			continue
		# No superponer obstáculos
		var choca := false
		for obs in _obstaculos:
			var op : Vector2 = obs["pos"]
			var os : Vector2 = obs["size"]
			if abs(p.x - op.x) < os.x * 0.6 + 30 and abs(p.y - op.y) < os.y * 0.6 + 30:
				choca = true
				break
		if not choca:
			return p
	return Vector2(randf_range(-300, 300), randf_range(-200, 200))

# ─────────────────────────────────────────────────────────────
#  UI
# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	# Panel contador arriba-izquierda
	var panel_top := ColorRect.new()
	panel_top.color    = Color(0.05, 0.05, 0.15, 0.85)
	panel_top.position = Vector2(0, 0)
	panel_top.size     = Vector2(1280, 68)
	ui.add_child(panel_top)

	# Icono de moneda/objeto
	var RUTA_MONEDA := _config.get("objeto_textura", "res://assets/ui/Moneda.png")
	if not ResourceLoader.exists(RUTA_MONEDA):
		RUTA_MONEDA = "res://assets/ui/Moneda.png"
	if ResourceLoader.exists(RUTA_MONEDA):
		var ico := TextureRect.new()
		ico.texture     = load(RUTA_MONEDA)
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ico.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		ico.position = Vector2(14, 10)
		ico.size     = Vector2(48, 48)
		ui.add_child(ico)

	# Contador
	_lbl_contador = Label.new()
	_lbl_contador.position = Vector2(68, 14)
	_lbl_contador.add_theme_font_size_override("font_size", 30)
	_lbl_contador.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	_lbl_contador.text = "0 / %d" % _total_obj
	ui.add_child(_lbl_contador)

	# Barra de progreso
	_barra_progreso = ProgressBar.new()
	_barra_progreso.position = Vector2(200, 22)
	_barra_progreso.size     = Vector2(400, 26)
	_barra_progreso.max_value = _total_obj
	_barra_progreso.value     = 0
	_barra_progreso.show_percentage = false
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.3, 0.9, 0.3)
	sty.corner_radius_top_left = 8; sty.corner_radius_top_right = 8
	sty.corner_radius_bottom_left = 8; sty.corner_radius_bottom_right = 8
	_barra_progreso.add_theme_stylebox_override("fill", sty)
	var sty_bg := StyleBoxFlat.new()
	sty_bg.bg_color = Color(0.1, 0.1, 0.2)
	_barra_progreso.add_theme_stylebox_override("background", sty_bg)
	ui.add_child(_barra_progreso)

	# Título de misión
	_lbl_titulo = Label.new()
	_lbl_titulo.position = Vector2(640, 14)
	_lbl_titulo.size     = Vector2(400, 40)
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.add_theme_font_size_override("font_size", 22)
	_lbl_titulo.add_theme_color_override("font_color", Color(0.8, 0.9, 1))
	_lbl_titulo.text = _config.get("titulo", "Recolecta los objetos")
	ui.add_child(_lbl_titulo)

	# Tiempo (si aplica)
	if _tiempo_max > 0:
		_lbl_tiempo = Label.new()
		_lbl_tiempo.position = Vector2(1080, 14)
		_lbl_tiempo.size     = Vector2(190, 40)
		_lbl_tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_lbl_tiempo.add_theme_font_size_override("font_size", 28)
		_lbl_tiempo.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		_lbl_tiempo.text = "⏱ %d" % int(_tiempo)
		ui.add_child(_lbl_tiempo)

	# Botón volver
	var btn_volver := Button.new()
	btn_volver.text = "✕"
	btn_volver.position = Vector2(1240, 12)
	btn_volver.size     = Vector2(36, 44)
	btn_volver.add_theme_font_size_override("font_size", 20)
	btn_volver.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)
	ui.add_child(btn_volver)

	# Joystick virtual (esquina inf-izquierda)
	_crear_joystick_virtual(ui)

# ─────────────────────────────────────────────────────────────
#  JOYSTICK VIRTUAL
# ─────────────────────────────────────────────────────────────
var _joy_base      : Control = null
var _joy_knob      : Control = null
var _joy_touch_id  : int     = -1
var _joy_centro    : Vector2 = Vector2.ZERO
const JOY_RADIO    : float   = 60.0

func _crear_joystick_virtual(parent: Node) -> void:
	_joy_base = ColorRect.new()
	_joy_base.color    = Color(0.5, 0.5, 1, 0.22)
	_joy_base.size     = Vector2(JOY_RADIO * 2, JOY_RADIO * 2)
	_joy_base.position = Vector2(40, 580)
	# Redondear via StyleBox en un Panel
	parent.add_child(_joy_base)

	_joy_knob = ColorRect.new()
	_joy_knob.color = Color(0.7, 0.7, 1, 0.55)
	_joy_knob.size  = Vector2(44, 44)
	_joy_knob.position = _joy_base.position + Vector2(JOY_RADIO - 22, JOY_RADIO - 22)
	parent.add_child(_joy_knob)

	_joy_centro = _joy_base.position + Vector2(JOY_RADIO, JOY_RADIO)

# ─────────────────────────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not _activo or _completado:
		return
	# Teclado / gamepad
	_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):  _dir.x += 1
	if Input.is_action_pressed("ui_left"):   _dir.x -= 1
	if Input.is_action_pressed("ui_down"):   _dir.y += 1
	if Input.is_action_pressed("ui_up"):     _dir.y -= 1

	# Touch joystick
	if event is InputEventScreenTouch:
		var area := Rect2(_joy_base.position - Vector2(10,10), _joy_base.size + Vector2(20,20))
		if event.pressed and area.has_point(event.position) and _joy_touch_id == -1:
			_joy_touch_id = event.index
		elif not event.pressed and event.index == _joy_touch_id:
			_joy_touch_id = -1
			_dir = Vector2.ZERO
			_joy_knob.position = _joy_centro - Vector2(22, 22)

	if event is InputEventScreenDrag and event.index == _joy_touch_id:
		var delta := event.position - _joy_centro
		if delta.length() > JOY_RADIO:
			delta = delta.normalized() * JOY_RADIO
		_joy_knob.position = _joy_centro + delta - Vector2(22, 22)
		_dir = delta / JOY_RADIO

# ─────────────────────────────────────────────────────────────
#  LOOP PRINCIPAL
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if not _activo or _completado:
		return

	# Mover Mati
	if _dir.length() > 0.1:
		var mov := _dir.normalized() * _velocidad_real * delta
		var nueva := _mati.position + mov
		# Límites
		nueva.x = clamp(nueva.x, LIMITE_IZQ + 40, LIMITE_DER - 40)
		nueva.y = clamp(nueva.y, LIMITE_ARR + 50, LIMITE_ABA - 10)
		# Colisión con obstáculos
		if not _colisiona_obs(nueva):
			_mati.position = nueva
		# Espejo horizontal
		if _dir.x > 0.1:
			_mati.scale.x = 1.0
		elif _dir.x < -0.1:
			_mati.scale.x = -1.0

	# Verificar recolección
	for obj_data in _objetos:
		if not obj_data["activo"]:
			continue
		var obj : Node2D = obj_data["node"]
		if _mati.global_position.distance_to(obj.global_position) < _radio_real:
			_recolectar(obj_data)

	# Temporizador
	if _tiempo_max > 0:
		_tiempo -= delta
		if _lbl_tiempo:
			_lbl_tiempo.text = "⏱ %d" % max(0, int(_tiempo))
			if _tiempo < 15:
				_lbl_tiempo.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		if _tiempo <= 0:
			_tiempo_agotado()

func _colisiona_obs(pos: Vector2) -> bool:
	for obs in _obstaculos:
		var op  : Vector2 = obs["pos"]
		var os  : Vector2 = obs["size"]
		if abs(pos.x - op.x) < os.x * 0.5 + MATI_RADIO and \
		   abs(pos.y - op.y) < os.y * 0.5 + MATI_RADIO:
			return true
	return false

# ─────────────────────────────────────────────────────────────
#  RECOLECCIÓN
# ─────────────────────────────────────────────────────────────
func _recolectar(obj_data: Dictionary) -> void:
	obj_data["activo"] = false
	var obj : Node2D = obj_data["node"]
	_recolectados += 1

	# Partículas burst (reutiliza moneda_burst con color personalizado)
	_moneda_burst.lanzar(self, obj.global_position)

	# Número flotante "+1"
	_mostrar_plus_uno(obj.global_position)

	# Sonido
	if get_node_or_null("/root/MusicaManager"):
		MusicaManager.play_sfx("moneda")

	# Efecto visual de recolección
	if _efectos:
		_efectos.estrella_burst(get_tree().root, obj.global_position, 4)

	# Animación de recolección (escala up y fade)
	var tw := create_tween()
	tw.tween_property(obj, "scale", Vector2(1.6, 1.6), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(obj, "scale", Vector2(0.0, 0.0), 0.18)\
		.set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(obj, "modulate:a", 0.0, 0.18)
	tw.tween_callback(obj.queue_free)

	# Actualizar UI
	_lbl_contador.text = "%d / %d" % [_recolectados, _total_obj]
	_barra_progreso.value = _recolectados

	# Animación de Mati al recoger
	_animador.interaccion(_mati)

	if _recolectados >= _total_obj:
		await get_tree().create_timer(0.4).timeout
		_completar()

func _mostrar_plus_uno(pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = "+1"
	lbl.position = pos + Vector2(randf_range(-15, 15), -20)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.2))
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 55, 0.65)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65)
	tw.tween_callback(lbl.queue_free)

# ─────────────────────────────────────────────────────────────
#  INTRO
# ─────────────────────────────────────────────────────────────
func _mostrar_intro() -> void:
	_activo = false
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var cl := CanvasLayer.new(); add_child(cl); cl.add_child(overlay)

	var panel := VBoxContainer.new()
	panel.position = Vector2(390, 160)
	panel.size     = Vector2(500, 400)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 16)
	overlay.add_child(panel)

	var lbl_t := Label.new()
	lbl_t.text = _config.get("titulo", "Minijuego")
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 36)
	lbl_t.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	panel.add_child(lbl_t)

	var lbl_d := Label.new()
	lbl_d.text = _config.get("descripcion", "")
	lbl_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_d.add_theme_font_size_override("font_size", 22)
	lbl_d.add_theme_color_override("font_color", Color(0.9, 0.9, 1))
	lbl_d.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_d.custom_minimum_size = Vector2(460, 60)
	panel.add_child(lbl_d)

	var lbl_obj := Label.new()
	lbl_obj.text = "Objetivo: recolectar %d %s" % [_total_obj, _config.get("objeto_nombre", "objetos")]
	lbl_obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_obj.add_theme_font_size_override("font_size", 20)
	lbl_obj.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	panel.add_child(lbl_obj)

	if _tiempo_max > 0:
		var lbl_ti := Label.new()
		lbl_ti.text = "Tiempo: %d segundos" % int(_tiempo_max)
		lbl_ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ti.add_theme_font_size_override("font_size", 18)
		lbl_ti.add_theme_color_override("font_color", Color(1, 0.75, 0.3))
		panel.add_child(lbl_ti)

	var btn := Button.new()
	btn.text = "¡Empezar!"
	btn.custom_minimum_size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 26)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.1, 0.65, 0.2)
	sty.corner_radius_top_left = 14; sty.corner_radius_top_right = 14
	sty.corner_radius_bottom_left = 14; sty.corner_radius_bottom_right = 14
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_stylebox_override("hover",  sty)
	btn.pressed.connect(func():
		overlay.queue_free()
		cl.queue_free()
		_activo = true
	)
	panel.add_child(btn)

# ─────────────────────────────────────────────────────────────
#  COMPLETAR
# ─────────────────────────────────────────────────────────────
func _completar() -> void:
	_completado = true
	_activo     = false

	_animador.victoria(_mati)
	var cel_script = load("res://scripts/celebracion.gd")
	if cel_script:
		cel_script.lanzar(get_tree().root)
	if get_node_or_null("/root/MusicaManager"):
		MusicaManager.musica_victoria()

	# Guardar si tiene seccion_id
	var sec_id := int(_config.get("seccion_id", 0))
	var monedas_ganar := int(_config.get("monedas", 8))
	if sec_id > 0:
		var datos: Dictionary = _guardado.cargar()
		var secciones : Dictionary = datos.get("secciones", {})
		secciones[str(sec_id)] = {"completada": true, "perfecta": true}
		_guardado.guardar(
			datos.get("nombre", "Jugador"),
			int(datos.get("nivel", 1)),
			int(datos.get("estrellas", 0)),
			int(datos.get("monedas", 0)) + monedas_ganar,
			datos.get("mundo1_completado", false),
			secciones
		)
	else:
		_guardado.sumar_monedas(monedas_ganar)

	await get_tree().create_timer(0.9).timeout
	_mostrar_panel_victoria(monedas_ganar)

func _tiempo_agotado() -> void:
	if _completado:
		return
	_completado = true
	_activo     = false
	await get_tree().create_timer(0.3).timeout
	_mostrar_panel_derrota()

func _mostrar_panel_victoria(monedas: int) -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	cl.add_child(overlay)

	var panel := VBoxContainer.new()
	panel.position = Vector2(390, 170)
	panel.size     = Vector2(500, 380)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 20)
	overlay.add_child(panel)

	var lbl_t := Label.new()
	lbl_t.text = "🏆 ¡Misión completada!"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 38)
	lbl_t.add_theme_color_override("font_color", Color(1, 0.9, 0.1))
	panel.add_child(lbl_t)

	var lbl_m := Label.new()
	lbl_m.text = "+%d monedas" % monedas
	lbl_m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_m.add_theme_font_size_override("font_size", 28)
	lbl_m.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	panel.add_child(lbl_m)

	var lbl_r := Label.new()
	lbl_r.text = "Recogiste: %d / %d" % [_recolectados, _total_obj]
	lbl_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_r.add_theme_font_size_override("font_size", 22)
	lbl_r.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	panel.add_child(lbl_r)

	var btn := Button.new()
	btn.text = "Continuar"
	btn.custom_minimum_size = Vector2(200, 52)
	btn.add_theme_font_size_override("font_size", 24)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.1, 0.65, 0.2)
	sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
	sty.corner_radius_bottom_left = 12; sty.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_stylebox_override("hover",  sty)
	btn.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)
	panel.add_child(btn)

func _mostrar_panel_derrota() -> void:
	var cl := CanvasLayer.new(); add_child(cl)
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	cl.add_child(overlay)

	var panel := VBoxContainer.new()
	panel.position = Vector2(390, 200)
	panel.size     = Vector2(500, 320)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 18)
	overlay.add_child(panel)

	var lbl_t := Label.new()
	lbl_t.text = "⏱ ¡Se acabó el tiempo!"
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 34)
	lbl_t.add_theme_color_override("font_color", Color(1, 0.5, 0.4))
	panel.add_child(lbl_t)

	var lbl_r := Label.new()
	lbl_r.text = "Recogiste %d de %d" % [_recolectados, _total_obj]
	lbl_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_r.add_theme_font_size_override("font_size", 22)
	lbl_r.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	panel.add_child(lbl_r)

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
	btn_reintentar.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/MinijuegoRecoleccion.tscn")
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
	btn_salir.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")
	)
	panel.add_child(btn_salir)

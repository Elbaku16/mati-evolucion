extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MINIJUEGO CARRERA ESPACIAL — desplazamiento lateral automático
#
#  Mati avanza automáticamente hacia la derecha.
#  El jugador toca ARRIBA / ABAJO (o botones táctiles) para esquivar.
#  Puertas matemáticas: 2 caminos, elegir el correcto da ventaja.
#  Al llegar a la meta: pantalla de resultados.
#
#  Config (user://carrera_config.json):
#    {
#      "titulo":       "Carrera Espacial",
#      "distancia":    2000,       # px hasta la meta
#      "velocidad":    260,        # velocidad base
#      "monedas_max":  15,
#      "seccion_id":   400,
#      "escena_origen":"res://scenes/Mapa.tscn"
#    }
# ═══════════════════════════════════════════════════════════════

static func guardar_config(cfg: Dictionary) -> void:
	const TEMP := "user://carrera_config.json"
	var f := FileAccess.open(TEMP, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))
		f.close()

func _leer_config() -> Dictionary:
	var defaults := {
		"titulo":        "Carrera Espacial",
		"distancia":     2000,
		"velocidad":     260,
		"monedas_max":   15,
		"seccion_id":    0,
		"escena_origen": "res://scenes/Mapa.tscn"
	}
	const TEMP := "user://carrera_config.json"
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
#  CONSTANTES
# ─────────────────────────────────────────────────────────────
const LANE_Y   : Array = [220.0, 360.0, 500.0]   # 3 carriles verticales
const MATI_X   : float = 160.0                   # posición X fija de Mati
const LANE_MID : int   = 1                        # carril inicial (centro)

const OBSTACULO_INTERVALO_MIN : float = 1.2
const OBSTACULO_INTERVALO_MAX : float = 2.4
const PUERTA_INTERVALO_MIN    : float = 5.0
const PUERTA_INTERVALO_MAX    : float = 9.0
const MONEDA_INTERVALO_MIN    : float = 0.8
const MONEDA_INTERVALO_MAX    : float = 1.8

# ─────────────────────────────────────────────────────────────
#  ESTADO
# ─────────────────────────────────────────────────────────────
var _config     : Dictionary = {}
var _guardado                 = null
var _efectos                  = null

var _etapa       : String = "intro"   # intro | corriendo | puerta | fin
var _carril      : int    = LANE_MID
var _target_y    : float  = LANE_Y[LANE_MID]
var _velocidad   : float  = 260.0
var _distancia   : float  = 0.0
var _dist_max    : float  = 2000.0
var _monedas     : int    = 0
var _desafios_ok : int    = 0
var _vidas       : int    = 3
var _invencible  : float  = 0.0   # segundos de invencibilidad tras golpe

var _tiempo_obs   : float = 0.0
var _prox_obs     : float = 1.5
var _tiempo_mon   : float = 0.0
var _prox_mon     : float = 1.0
var _tiempo_puert : float = 0.0
var _prox_puert   : float = 6.0

var _bg_offset    : float = 0.0

# Nodos
var _mati_node   : Node2D  = null
var _obstaculos  : Array   = []
var _monedas_arr : Array   = []
var _puertas_arr : Array   = []

# UI
var _lbl_dist    : Label   = null
var _lbl_monedas : Label   = null
var _corazones   : Array   = []   # 3 Label "❤"
var _barra_prog  : ColorRect = null
var _lbl_vel     : Label   = null

# Overlay de puerta activa
var _canvas_puerta : CanvasLayer = null
var _puerta_data   : Dictionary = {}

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_guardado = load("res://scripts/guardado.gd").new()
	_efectos  = load("res://scripts/efectos_ui.gd")
	_config   = _leer_config()

	_velocidad = float(_config.get("velocidad", 260))
	_dist_max  = float(_config.get("distancia", 2000))

	_construir_escena()
	_mostrar_intro()

# ─────────────────────────────────────────────────────────────
#  CONSTRUCCIÓN DE LA ESCENA
# ─────────────────────────────────────────────────────────────
func _construir_escena() -> void:
	# Fondo procedural (cielo espacial con scroll)
	var bg := _Fondo.new()
	bg.name = "FondoScroll"
	bg.z_index = -10
	add_child(bg)

	# Suelo decorativo (3 líneas de carril)
	var pista := _Pista.new()
	pista.z_index = -5
	add_child(pista)

	# Mati
	_mati_node = _MatiCorredor.new()
	_mati_node.position = Vector2(MATI_X, LANE_Y[_carril])
	_mati_node.z_index  = 10
	add_child(_mati_node)

	# UI (CanvasLayer para que no scroll)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 50
	add_child(ui_layer)

	# Distancia
	_lbl_dist = Label.new()
	_lbl_dist.text     = "0 m"
	_lbl_dist.position = Vector2(560, 12)
	_lbl_dist.size     = Vector2(160, 32)
	_lbl_dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_dist.add_theme_font_size_override("font_size", 22)
	_lbl_dist.add_theme_color_override("font_color", Color.WHITE)
	ui_layer.add_child(_lbl_dist)

	# Monedas
	_lbl_monedas = Label.new()
	_lbl_monedas.text     = "🪙 0"
	_lbl_monedas.position = Vector2(16, 12)
	_lbl_monedas.size     = Vector2(120, 32)
	_lbl_monedas.add_theme_font_size_override("font_size", 22)
	_lbl_monedas.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	ui_layer.add_child(_lbl_monedas)

	# Corazones
	for i in 3:
		var lbl_c := Label.new()
		lbl_c.text     = "❤"
		lbl_c.position = Vector2(1120 + i * 42, 10)
		lbl_c.size     = Vector2(38, 32)
		lbl_c.add_theme_font_size_override("font_size", 26)
		lbl_c.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		ui_layer.add_child(lbl_c)
		_corazones.append(lbl_c)

	# Barra de progreso
	var bg_barra := ColorRect.new()
	bg_barra.color    = Color(0.1, 0.1, 0.1, 0.7)
	bg_barra.position = Vector2(200, 16)
	bg_barra.size     = Vector2(360, 18)
	ui_layer.add_child(bg_barra)

	_barra_prog = ColorRect.new()
	_barra_prog.color    = Color(0.3, 0.9, 0.4)
	_barra_prog.position = Vector2(200, 16)
	_barra_prog.size     = Vector2(0, 18)
	ui_layer.add_child(_barra_prog)

	var lbl_meta := Label.new()
	lbl_meta.text     = "🏁"
	lbl_meta.position = Vector2(558, 10)
	lbl_meta.add_theme_font_size_override("font_size", 20)
	ui_layer.add_child(lbl_meta)

	# Botones táctiles (ARRIBA / ABAJO)
	var btn_arr := Button.new()
	btn_arr.text     = "▲"
	btn_arr.position = Vector2(16, 580)
	btn_arr.size     = Vector2(90, 90)
	btn_arr.add_theme_font_size_override("font_size", 36)
	btn_arr.pressed.connect(func(): _mover_carril(-1))
	ui_layer.add_child(btn_arr)

	var btn_aba := Button.new()
	btn_aba.text     = "▼"
	btn_aba.position = Vector2(16, 490)
	btn_aba.size     = Vector2(90, 90)
	btn_aba.add_theme_font_size_override("font_size", 36)
	btn_aba.pressed.connect(func(): _mover_carril(1))
	ui_layer.add_child(btn_aba)

	# Botón pausa / salir
	var btn_sal := Button.new()
	btn_sal.text     = "✕ Salir"
	btn_sal.position = Vector2(16, 668)
	btn_sal.size     = Vector2(130, 42)
	btn_sal.add_theme_font_size_override("font_size", 16)
	btn_sal.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)
	ui_layer.add_child(btn_sal)

	set_process_input(true)

# ─────────────────────────────────────────────────────────────
#  INTRO
# ─────────────────────────────────────────────────────────────
func _mostrar_intro() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 60
	add_child(canvas)

	var ovl := ColorRect.new()
	ovl.color = Color(0, 0, 0.1, 0.88)
	ovl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ovl.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(ovl)

	var lbl := Label.new()
	lbl.text = "🚀 " + str(_config.get("titulo", "Carrera Espacial")) + "\n▲ ▼ para esquivar   🪙 recolecta monedas\n¡Llega a la meta!"
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	ovl.add_child(lbl)

	var btn := Button.new()
	btn.text = "▶ Comenzar"
	btn.size = Vector2(220, 60)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	btn.offset_left = -110; btn.offset_top = -100
	btn.offset_right = 110; btn.offset_bottom = -40
	btn.add_theme_font_size_override("font_size", 26)
	ovl.add_child(btn)
	btn.pressed.connect(func():
		canvas.queue_free()
		_etapa = "corriendo"
	)

# ─────────────────────────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _etapa != "corriendo":
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP,   KEY_W: _mover_carril(-1)
			KEY_DOWN, KEY_S: _mover_carril(1)

func _mover_carril(dir: int) -> void:
	if _etapa != "corriendo":
		return
	_carril = clampi(_carril + dir, 0, 2)
	_target_y = LANE_Y[_carril]

# ─────────────────────────────────────────────────────────────
#  LOOP PRINCIPAL
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _etapa != "corriendo":
		return

	# Mover Mati al carril objetivo suavemente
	var my := _mati_node.position.y
	_mati_node.position.y = move_toward(my, _target_y, 420.0 * delta)

	# Avanzar distancia
	var avance := _velocidad * delta
	_distancia += avance
	_bg_offset += avance

	# Mover todos los objetos hacia la izquierda
	for obs in _obstaculos:
		obs.position.x -= _velocidad * delta
	for mon in _monedas_arr:
		mon.position.x -= _velocidad * delta
	for puerta in _puertas_arr:
		puerta.position.x -= (_velocidad * 0.7) * delta

	# Limpiar objetos fuera de pantalla
	_obstaculos  = _obstaculos.filter(func(n): return n.position.x > -100 or not n.is_inside_tree())
	_monedas_arr = _monedas_arr.filter(func(n): return n.position.x > -100 or not n.is_inside_tree())
	_puertas_arr = _puertas_arr.filter(func(n): return n.position.x > -100 or not n.is_inside_tree())

	# Spawnear
	_tiempo_obs   += delta
	_tiempo_mon   += delta
	_tiempo_puert += delta
	if _tiempo_obs >= _prox_obs:
		_tiempo_obs = 0.0
		_prox_obs = randf_range(OBSTACULO_INTERVALO_MIN, OBSTACULO_INTERVALO_MAX)
		_spawn_obstaculo()
	if _tiempo_mon >= _prox_mon:
		_tiempo_mon = 0.0
		_prox_mon = randf_range(MONEDA_INTERVALO_MIN, MONEDA_INTERVALO_MAX)
		_spawn_moneda()
	if _tiempo_puert >= _prox_puert:
		_tiempo_puert = 0.0
		_prox_puert = randf_range(PUERTA_INTERVALO_MIN, PUERTA_INTERVALO_MAX)
		_spawn_puerta_matematica()

	# Colisiones
	if _invencible > 0.0:
		_invencible -= delta
	else:
		_verificar_colisiones()

	# UI
	_lbl_dist.text = "%d m" % int(_distancia)
	var pct := clampf(_distancia / _dist_max, 0.0, 1.0)
	_barra_prog.size.x = 360.0 * pct

	# Fondo: actualizar offset
	var fondo : Node = get_node_or_null("FondoScroll")
	if fondo and fondo.has_method("set_offset"):
		fondo.call("set_offset", _bg_offset)

	# Meta
	if _distancia >= _dist_max:
		_etapa = "fin"
		_fin_carrera(true)

# ─────────────────────────────────────────────────────────────
#  SPAWN DE OBJETOS
# ─────────────────────────────────────────────────────────────
func _spawn_obstaculo() -> void:
	var carril := randi() % 3
	var obs := _Obstaculo.new()
	obs.position = Vector2(1340, LANE_Y[carril])
	add_child(obs)
	_obstaculos.append(obs)

func _spawn_moneda() -> void:
	var carril := randi() % 3
	var mon := _Moneda.new()
	mon.position = Vector2(1340, LANE_Y[carril])
	add_child(mon)
	_monedas_arr.append(mon)

func _spawn_puerta_matematica() -> void:
	# Genera un problema y 2 caminos: arriba (carril 0 o 1) y abajo (1 o 2)
	var reto := _generar_reto_carrera()
	var puerta := _PuertaCarrera.new()
	puerta.reto = reto
	puerta.position = Vector2(1340, 360)
	add_child(puerta)
	_puertas_arr.append(puerta)

func _generar_reto_carrera() -> Dictionary:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var tipos := ["suma", "resta", "multi"]
	var tipo  := tipos[randi() % tipos.size()]
	match tipo:
		"suma":
			var a := rng.randi_range(2, 12)
			var b := rng.randi_range(2, 12)
			return {"pregunta": "%d + %d" % [a, b], "respuesta": a + b,
			        "tipo": "suma"}
		"resta":
			var a2 := rng.randi_range(5, 15)
			var b2 := rng.randi_range(1, a2)
			return {"pregunta": "%d − %d" % [a2, b2], "respuesta": a2 - b2,
			        "tipo": "resta"}
		"multi":
			var a3 := rng.randi_range(2, 6)
			var b3 := rng.randi_range(2, 6)
			return {"pregunta": "%d × %d" % [a3, b3], "respuesta": a3 * b3,
			        "tipo": "multi"}
	return {"pregunta": "1+1", "respuesta": 2, "tipo": "suma"}

# ─────────────────────────────────────────────────────────────
#  COLISIONES
# ─────────────────────────────────────────────────────────────
func _verificar_colisiones() -> void:
	var mx := _mati_node.position.x
	var my := _mati_node.position.y
	const HIT_R := 36.0

	# Obstáculos
	for obs in _obstaculos:
		if obs.position.distance_to(Vector2(mx, my)) < HIT_R + 24:
			_golpe()
			obs.queue_free()
			_obstaculos.erase(obs)
			return

	# Monedas
	for mon in _monedas_arr:
		if mon.position.distance_to(Vector2(mx, my)) < HIT_R + 20:
			_recoger_moneda(mon)
			return

	# Puertas matemáticas
	for puerta in _puertas_arr:
		if not puerta.has_method("get_carriles"):
			continue
		var info : Dictionary = puerta.call("get_carriles")
		# La puerta bloquea toda la pantalla — detectar si Mati entra en su zona
		var px := puerta.position.x
		if px < mx + 60 and px > mx - 20:
			_etapa = "puerta"
			_abrir_panel_puerta(puerta, info)
			puerta.queue_free()
			_puertas_arr.erase(puerta)
			return

func _golpe() -> void:
	_vidas -= 1
	_invencible = 1.5
	if _efectos:
		_efectos.flash_incorrecto(get_tree().root)
		_efectos.sacudida(_mati_node, 6.0, 0.3)
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx("golpe")
	# Actualizar corazones UI
	for i in _corazones.size():
		_corazones[i].modulate = Color(1, 1, 1) if i < _vidas else Color(0.3, 0.3, 0.3)
	if _vidas <= 0:
		_etapa = "fin"
		_fin_carrera(false)

func _recoger_moneda(mon: Node) -> void:
	if _efectos:
		_efectos.moneda_flotante(get_tree().root, mon.position, 1)
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx("moneda")
	_monedas += 1
	_lbl_monedas.text = "🪙 %d" % _monedas
	mon.queue_free()
	_monedas_arr.erase(mon)

# ─────────────────────────────────────────────────────────────
#  PANEL DE PUERTA MATEMÁTICA
# ─────────────────────────────────────────────────────────────
func _abrir_panel_puerta(puerta: Node, _info: Dictionary) -> void:
	# Obtener el reto de la puerta
	var reto : Dictionary = {}
	if puerta.has_method("get_reto"):
		reto = puerta.call("get_reto")
	else:
		reto = _generar_reto_carrera()

	var correcto : int = int(reto.get("respuesta", 2))
	var incorrecto : int = correcto + (randi() % 4 + 2) * (1 if randf() > 0.5 else -1)
	if incorrecto <= 0: incorrecto = correcto + 3
	var opciones := [correcto, incorrecto]
	opciones.shuffle()

	_canvas_puerta = CanvasLayer.new()
	_canvas_puerta.layer = 70
	add_child(_canvas_puerta)

	var ovl := ColorRect.new()
	ovl.color = Color(0, 0, 0, 0.75)
	ovl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ovl.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas_puerta.add_child(ovl)

	var lbl_q := Label.new()
	lbl_q.text = "⚡ Elige el resultado correcto ⚡\n\n%s = ?" % reto.get("pregunta", "?")
	lbl_q.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_q.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl_q.offset_bottom = -100.0
	lbl_q.add_theme_font_size_override("font_size", 36)
	lbl_q.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	ovl.add_child(lbl_q)

	# Dos botones grandes
	var colores_btn := [Color(0.1, 0.5, 0.9), Color(0.7, 0.2, 0.2)]
	for i in 2:
		var btn := Button.new()
		btn.text = str(opciones[i])
		btn.position = Vector2(200 + i * 440, 540)
		btn.size     = Vector2(240, 80)
		btn.add_theme_font_size_override("font_size", 40)
		ovl.add_child(btn)
		var val := opciones[i]
		btn.pressed.connect(func():
			_evaluar_puerta(val == correcto)
		)

func _evaluar_puerta(correcto_elegido: bool) -> void:
	if _canvas_puerta:
		_canvas_puerta.queue_free()
		_canvas_puerta = null

	if correcto_elegido:
		if _efectos:
			_efectos.flash_correcto(get_tree().root)
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx("correcto")
		_velocidad = minf(_velocidad * 1.2, 420.0)   # boost de velocidad
		_monedas  += 2
		_lbl_monedas.text = "🪙 %d" % _monedas
		_desafios_ok += 1
	else:
		if _efectos:
			_efectos.flash_incorrecto(get_tree().root)
		_golpe()

	_etapa = "corriendo"

# ─────────────────────────────────────────────────────────────
#  FIN DE CARRERA
# ─────────────────────────────────────────────────────────────
func _fin_carrera(llego_a_meta: bool) -> void:
	var monedas_max : int = int(_config.get("monedas_max", 15))
	var monedas_ganadas : int
	if llego_a_meta:
		monedas_ganadas = min(_monedas + 5, monedas_max)
	else:
		monedas_ganadas = min(_monedas, monedas_max)

	var sec_id : int = int(_config.get("seccion_id", 0))
	var datos := _guardado.cargar()
	if llego_a_meta and sec_id > 0:
		var secs : Array = datos.get("secciones", [])
		if not sec_id in secs:
			secs.append(sec_id)
		datos["secciones"] = secs
	datos["monedas"]   = int(datos.get("monedas",   0)) + monedas_ganadas
	datos["estrellas"] = int(datos.get("estrellas", 0)) + (2 if llego_a_meta else 0)
	if llego_a_meta:
		var sid := int(_config.get("seccion_id", 0))
		if sid == 122: load("res://scripts/misiones.gd").marcar_completa("p2_carrera", datos)
	var arch := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
	if arch:
		arch.store_string(JSON.stringify(datos))
		arch.close()

	if llego_a_meta:
		if _efectos:
			_efectos.flash_dorado(get_tree().root)
		var cel = load("res://scripts/celebracion.gd")
		if cel: cel.lanzar(get_tree().root)
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx("fanfare")

	# Panel de resultados
	var canvas := CanvasLayer.new()
	canvas.layer = 80
	add_child(canvas)

	var ovl := ColorRect.new()
	ovl.color = Color(0.0, 0.03, 0.10, 0.92)
	ovl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ovl.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(ovl)

	var titulo := "🏁 ¡Meta!" if llego_a_meta else "💥 Nave destruida"
	var lbl := Label.new()
	lbl.text = "%s\n\n📏 %d m recorridos\n🪙 +%d monedas\n⭐ Desafíos: %d" % [
		titulo,
		int(_distancia),
		monedas_ganadas,
		_desafios_ok
	]
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.offset_bottom = -80.0
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if llego_a_meta else Color(1.0, 0.5, 0.3))
	ovl.add_child(lbl)

	var btn := Button.new()
	btn.text = "Continuar ▶"
	btn.size = Vector2(240, 60)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	btn.offset_left = -120; btn.offset_top = -100
	btn.offset_right = 120; btn.offset_bottom = -40
	btn.add_theme_font_size_override("font_size", 26)
	ovl.add_child(btn)
	btn.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)

# ─────────────────────────────────────────────────────────────
#  CLASES INTERNAS
# ─────────────────────────────────────────────────────────────

class _Fondo extends Node2D:
	var _offset  : float = 0.0
	var _estrellas : Array = []
	var _planetas  : Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new(); rng.randomize()
		for _i in 60:
			_estrellas.append({
				"x": rng.randf_range(0, 1280),
				"y": rng.randf_range(0, 720),
				"r": rng.randf_range(1.0, 2.5),
				"speed": rng.randf_range(0.3, 0.8)
			})
		for _i in 3:
			_planetas.append({
				"x": rng.randf_range(400, 1200),
				"y": rng.randf_range(60, 280),
				"r": rng.randf_range(20, 50),
				"col": Color(rng.randf(), rng.randf() * 0.5 + 0.3, rng.randf(), 0.4),
				"speed": rng.randf_range(0.1, 0.25)
			})

	func set_offset(off: float) -> void:
		_offset = off
		queue_redraw()

	func _draw() -> void:
		# Fondo negro espacial
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.02, 0.01, 0.10))
		# Planetas
		for p in _planetas:
			var px := fmod(float(p["x"]) - _offset * float(p["speed"]), 1400.0)
			if px < -100: px += 1400
			draw_circle(Vector2(px, float(p["y"])), float(p["r"]), p["col"])
		# Estrellas parallax
		for s in _estrellas:
			var sx := fmod(float(s["x"]) - _offset * float(s["speed"]), 1280.0)
			if sx < 0: sx += 1280
			draw_circle(Vector2(sx, float(s["y"])), float(s["r"]), Color(1, 1, 1, 0.8))

class _Pista extends Node2D:
	func _draw() -> void:
		# 3 carriles horizontales
		var lane_y_arr := [220.0, 360.0, 500.0]
		for y in lane_y_arr:
			draw_line(Vector2(0, y), Vector2(1280, y),
			          Color(0.3, 0.4, 0.6, 0.35), 1.5)
		# Separadores de carril (guiones)
		for y in [290.0, 430.0]:
			var x := 0.0
			while x < 1280:
				draw_line(Vector2(x, y), Vector2(x + 40, y),
				          Color(0.3, 0.3, 0.5, 0.2), 1.0)
				x += 80.0

class _MatiCorredor extends Node2D:
	var _tiempo : float = 0.0
	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()
	func _draw() -> void:
		var t := _tiempo
		# Cuerpo nave pequeña (Mati como nave)
		draw_rect(Rect2(-28, -18, 56, 36), Color(0.3, 0.6, 0.9), true)
		draw_rect(Rect2(-28, -18, 56, 36), Color(0.6, 0.85, 1.0, 0.8), false, 2.0)
		# Cabina
		draw_arc(Vector2(-10, 0), 14, PI * 0.5, PI * 1.5, 24, Color(0.5, 0.8, 1.0), 2.0)
		# Llama propulsora
		var fl := Color(1.0, 0.5, 0.1, 0.7 + 0.25 * sin(t * 12))
		draw_circle(Vector2(-38 - sin(t * 10) * 3, 0), 10.0, fl)
		draw_circle(Vector2(-38 - sin(t * 13) * 2, 0), 6.0, Color(1, 0.9, 0.3, 0.6))

class _Obstaculo extends Node2D:
	var _tiempo : float = 0.0
	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()
	func _draw() -> void:
		var t := _tiempo
		# Asteroide
		var pts := PackedVector2Array()
		var n := 8
		for i in n:
			var ang := TAU * float(i) / float(n)
			var r   := 24.0 + sin(ang * 3.0 + t) * 6.0
			pts.append(Vector2(cos(ang) * r, sin(ang) * r))
		draw_colored_polygon(pts, Color(0.5, 0.4, 0.35))
		draw_polyline(pts + PackedVector2Array([pts[0]]),
		              Color(0.7, 0.6, 0.5), 2.0)
		draw_circle(Vector2(-6, -5), 5.0, Color(0.3, 0.25, 0.22, 0.6))

class _Moneda extends Node2D:
	var _tiempo : float = 0.0
	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()
	func _draw() -> void:
		var t := _tiempo
		draw_circle(Vector2(0, sin(t * 3) * 6), 12.0, Color(1.0, 0.85, 0.1))
		draw_arc(Vector2(0, sin(t * 3) * 6), 12.0, 0, TAU, 24,
		         Color(0.9, 0.7, 0.0), 2.0)
		draw_circle(Vector2(0, sin(t * 3) * 6), 6.0, Color(1.0, 0.95, 0.5, 0.6))

class _PuertaCarrera extends Node2D:
	var reto : Dictionary = {}

	func get_reto() -> Dictionary:
		return reto

	func get_carriles() -> Dictionary:
		return {}

	func _draw() -> void:
		# Marco de la puerta a través de los 3 carriles
		draw_rect(Rect2(-8, -200, 16, 400), Color(0.8, 0.8, 0.1, 0.9), true)
		draw_rect(Rect2(-8, -200, 16, 400), Color(1, 1, 0.5), false, 2.0)
		# Texto del reto
		# (en Godot 4 no hay draw_string fácil con emoji; se muestra básico)
		for y_off in [-100.0, 0.0, 100.0]:
			draw_arc(Vector2(0, y_off), 28, 0, TAU, 16,
			         Color(0.8, 0.8, 0.1, 0.5), 2.0)

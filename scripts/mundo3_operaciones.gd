extends Control

# ═══════════════════════════════════════════════════════════════
#  MUNDO 3 — PANTALLA DE OPERACIONES (PLANETA HONGOS)
# ═══════════════════════════════════════════════════════════════

var operaciones_node
var guardado_node

var pregunta_actual : Dictionary = {}
var botones_valores : Array      = []
var numero_pregunta : int        = 0
var aciertos        : int        = 0
var fallos          : int        = 0
var preguntas       : Array      = []
var indice_actual   : int        = 0
var seccion_actual  : int        = 11
var config_seccion  : Dictionary = {}
var mundo_completado_ahora : bool = false

const TOTAL_PREGUNTAS  : int = 5
const MONEDAS_SECCION  : int = 5
const MONEDAS_PERFECTA : int = 3

const OPERADORES = {
	"+": "res://assets/ui/op_suma.png",
	"-": "res://assets/ui/op_resta.png",
	"x": "res://assets/ui/op_mult.png"
}

const ESTRELLA_VACIA = "res://assets/ui/estrella_respuesta.png"

const SECCIONES = {
	# Fungi  — tabla del 3, ×2 al ×9
	11: { "tipo": "mult",       "tabla": 3, "min_factor": 2, "max_factor": 9 },
	# Brote  — tabla del 4, ×3 al ×9
	12: { "tipo": "mult",       "tabla": 4, "min_factor": 3, "max_factor": 9 },
	# Orbis  — tabla del 5, ×3 al ×9
	13: { "tipo": "mult",       "tabla": 5, "min_factor": 3, "max_factor": 9 },
	# Aliencita — tablas 3-7 mezcladas, factor ×3 al ×9
	14: { "tipo": "mult_mixto", "min": 3, "max": 7, "min_factor": 3         },
	# Blanco — tabla del 6, ×4 al ×9
	15: { "tipo": "mult",       "tabla": 6, "min_factor": 4, "max_factor": 9 },
	# Turbo  — tabla del 7, ×4 al ×9
	16: { "tipo": "mult",       "tabla": 7, "min_factor": 4, "max_factor": 9 },
	# Jefe   — tablas 4-9 mezcladas, factor ×5 al ×9 (máxima dificultad)
	17: { "tipo": "mult_mixto", "min": 4, "max": 9, "min_factor": 5         },
}

func _ruta_estrella(n: int) -> String:
	return "res://assets/ui/estrellas/%d.png" % n

# ─────────────────────────────────────────────────────────────
#  INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").musica_desafio()
	operaciones_node = load("res://scripts/operaciones.gd").new()
	guardado_node = load("res://scripts/guardado.gd").new()

	var datos = guardado_node.cargar()
	seccion_actual = int(datos.get("seccion_actual", 11))
	config_seccion = SECCIONES.get(seccion_actual, SECCIONES[11])

	_generar_preguntas()

	for nombre in ["LabelN1","LabelN2","LabelRes","LabelB0","LabelB1","LabelB2","LabelB3","LabelB4","LabelB5"]:
		if has_node(nombre):
			get_node(nombre).visible = false

	$Btn0.pressed.connect(_on_btn_presionado.bind(0))
	$Btn1.pressed.connect(_on_btn_presionado.bind(1))
	$Btn2.pressed.connect(_on_btn_presionado.bind(2))
	$Btn3.pressed.connect(_on_btn_presionado.bind(3))
	$Btn4.pressed.connect(_on_btn_presionado.bind(4))
	$Btn5.pressed.connect(_on_btn_presionado.bind(5))

	if has_node("PanelIntentar"):
		$PanelIntentar.visible = false

	actualizar_progreso()
	mostrar_pregunta()
	_crear_boton_casa()

func _crear_boton_casa() -> void:
	const RUTA_CASA = "res://assets/ui/Casa_transparente.png"
	var accion := func():
		get_tree().paused = false
		TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")
	if ResourceLoader.exists(RUTA_CASA):
		var btn := TextureButton.new()
		btn.texture_normal = load(RUTA_CASA)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.position = Vector2(10, 10)
		btn.size = Vector2(64, 64)
		btn.tooltip_text = "Volver al mapa"
		var sbe := StyleBoxEmpty.new()
		for estado in ["normal", "pressed", "hover", "focus", "disabled"]:
			btn.add_theme_stylebox_override(estado, sbe)
		btn.pressed.connect(accion)
		add_child(btn)
	else:
		var btn := Button.new()
		btn.text = "🏠"
		btn.add_theme_font_size_override("font_size", 22)
		btn.position = Vector2(12, 12)
		btn.size = Vector2(54, 48)
		btn.pressed.connect(accion)
		add_child(btn)

# ─────────────────────────────────────────────────────────────
#  GENERAR PREGUNTAS
# ─────────────────────────────────────────────────────────────
func _generar_preguntas() -> void:
	preguntas.clear()
	indice_actual = 0
	aciertos = 0
	fallos = 0

	for i in range(TOTAL_PREGUNTAS):
		preguntas.append(_generar_operacion())

func _generar_operacion() -> Dictionary:
	var tipo = config_seccion["tipo"]
	var num1: int
	var num2: int
	var op: String
	var respuesta: int

	match tipo:
		"mult":
			op = "x"
			var tabla      = int(config_seccion.get("tabla", 3))
			var min_factor = int(config_seccion.get("min_factor", 2))
			var max_factor = int(config_seccion.get("max_factor", 9))
			num1 = tabla
			num2 = randi_range(min_factor, max_factor)
			respuesta = num1 * num2
		"mult_mixto":
			op = "x"
			var min_t      = int(config_seccion.get("min", 3))
			var max_t      = int(config_seccion.get("max", 9))
			var min_factor = int(config_seccion.get("min_factor", 2))
			num1 = randi_range(min_t, max_t)
			num2 = randi_range(min_factor, 9)
			respuesta = num1 * num2

	return {
		"num1": num1,
		"num2": num2,
		"operacion": op,
		"respuesta": respuesta,
		"tipo": 0
	}

# ─────────────────────────────────────────────────────────────
#  BARRA DE PROGRESO
# ─────────────────────────────────────────────────────────────
func actualizar_progreso() -> void:
	var paso = int(round(float(numero_pregunta) / float(TOTAL_PREGUNTAS) * 10.0))
	var ruta = "res://assets/ui/progreso_%d.png" % clamp(paso, 0, 10)
	if ResourceLoader.exists(ruta):
		$BarraProgreso.texture = load(ruta)

# ─────────────────────────────────────────────────────────────
#  MOSTRAR PREGUNTA
# ─────────────────────────────────────────────────────────────
func mostrar_pregunta() -> void:
	if indice_actual >= preguntas.size():
		_terminar_seccion()
		return

	pregunta_actual = preguntas[indice_actual]

	var num1 = pregunta_actual["num1"]
	var num2 = pregunta_actual["num2"]
	var op   = pregunta_actual["operacion"]
	var res  = pregunta_actual["respuesta"]
	var tipo = pregunta_actual["tipo"]

	$Operador.texture = load(OPERADORES[op])

	match tipo:
		0:
			_cargar_numero($NumFaltante1, num1, false)
			_cargar_numero($NumFaltante2, num2, false)
			_cargar_numero($Respuesta,    res,  true)

	var correcta = res
	var opciones = [correcta]
	var intentos = 0
	while opciones.size() < 6 and intentos < 300:
		intentos += 1
		var rango = max(5, int(correcta / 2))
		var falsa = correcta + randi_range(-rango, rango)
		falsa = clamp(falsa, 0, 100)
		if falsa != correcta and falsa not in opciones:
			opciones.append(falsa)
	opciones.shuffle()
	botones_valores = opciones

	var btns = [$Btn0,$Btn1,$Btn2,$Btn3,$Btn4,$Btn5]
	for i in range(6):
		_cargar_numero_boton(btns[i], opciones[i])
		btns[i].modulate = Color(1,1,1,1)
		btns[i].disabled = false

# ─────────────────────────────────────────────────────────────
#  CARGA DE NÚMERO
# ─────────────────────────────────────────────────────────────
func _cargar_numero(nodo: TextureRect, numero: int, vacio: bool) -> void:
	for hijo in nodo.get_children():
		if hijo is Label:
			hijo.queue_free()
	if vacio:
		nodo.texture = load(ESTRELLA_VACIA)
		return
	nodo.texture = load(_ruta_estrella(numero))

func _cargar_numero_boton(btn: TextureButton, numero: int) -> void:
	for hijo in btn.get_children():
		if hijo is Label:
			hijo.queue_free()
	btn.texture_normal = load(_ruta_estrella(numero))

# ─────────────────────────────────────────────────────────────
#  RESPUESTA DEL JUGADOR
# ─────────────────────────────────────────────────────────────
func _on_btn_presionado(indice: int) -> void:
	var elegido = botones_valores[indice]
	var correcta = pregunta_actual["respuesta"]

	var btns = [$Btn0,$Btn1,$Btn2,$Btn3,$Btn4,$Btn5]
	for b in btns:
		b.disabled = true

	if elegido == correcta:
		btns[indice].modulate = Color(0.3, 1, 0.3, 1)
		_animar_boton_feedback(btns[indice], true)
		if get_node_or_null("/root/MusicaManager"):
			MusicaManager.play_sfx("correcto")
		aciertos += 1
		indice_actual += 1
		numero_pregunta += 1
		actualizar_progreso()
		await get_tree().create_timer(0.7).timeout

		if indice_actual < preguntas.size():
			mostrar_pregunta()
		else:
			_terminar_seccion()
	else:
		btns[indice].modulate = Color(1, 0.3, 0.3, 1)
		_animar_boton_feedback(btns[indice], false)
		if get_node_or_null("/root/MusicaManager"):
			MusicaManager.play_sfx("incorrecto")
		fallos += 1
		await get_tree().create_timer(0.7).timeout
		_mostrar_intentar_de_nuevo()

# ─────────────────────────────────────────────────────────────
#  INTÉNTALO DE NUEVO
# ─────────────────────────────────────────────────────────────
func _animar_boton_feedback(btn: TextureButton, correcto: bool) -> void:
	var orig_scale := btn.scale
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", orig_scale * 1.30, 0.12)
	tw.tween_property(btn, "scale", orig_scale,        0.18)

	var lbl := Label.new()
	lbl.text = "✓" if correcto else "✗"
	lbl.add_theme_font_size_override("font_size", 52)
	lbl.add_theme_color_override("font_color",
		Color(0.2, 1.0, 0.3) if correcto else Color(1.0, 0.25, 0.25))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.pivot_offset = Vector2(20, 26)
	lbl.scale        = Vector2(0.2, 0.2)
	lbl.modulate.a   = 0.0
	lbl.position     = btn.position + Vector2(btn.size.x * 0.5 - 20, -60)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.get_parent().add_child(lbl)

	var tl := create_tween()
	tl.set_parallel(true)
	tl.tween_property(lbl, "scale",      Vector2(1.0, 1.0), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tl.tween_property(lbl, "modulate:a", 1.0,               0.12)
	tl.chain().tween_interval(0.25)
	tl.chain().tween_property(lbl, "position:y", lbl.position.y - 35, 0.25)
	tl.chain().tween_property(lbl, "modulate:a", 0.0,                  0.20)
	tl.chain().tween_callback(func(): lbl.queue_free())

func _mostrar_intentar_de_nuevo() -> void:
	if has_node("PanelIntentar"):
		$PanelIntentar.visible = true
		await get_tree().create_timer(1.2).timeout
		$PanelIntentar.visible = false

	var btns = [$Btn0,$Btn1,$Btn2,$Btn3,$Btn4,$Btn5]
	for b in btns:
		b.modulate = Color(1,1,1,1)
		b.disabled = false

# ─────────────────────────────────────────────────────────────
#  TERMINAR SECCIÓN
# ─────────────────────────────────────────────────────────────
func _terminar_seccion() -> void:
	var perfecta = (fallos == 0)
	var monedas_ganadas = MONEDAS_SECCION
	if perfecta:
		monedas_ganadas += MONEDAS_PERFECTA

	var datos = guardado_node.cargar()
	var secciones = datos.get("secciones", {})
	var key = str(seccion_actual)
	var anterior = secciones.get(key, {})
	var ya_perfecta = anterior.get("perfecta", false)

	secciones[key] = {
		"completada" : true,
		"perfecta"   : perfecta or ya_perfecta
	}

	var monedas_totales = int(datos.get("monedas", 0)) + monedas_ganadas

	# Verificar si completó las 7 secciones del Mundo 3 (11-17)
	var todas_completas = true
	for i in range(11, 18):
		if not secciones.get(str(i), {}).get("completada", false):
			todas_completas = false
			break

	mundo_completado_ahora = todas_completas

	guardado_node.guardar(
		datos.get("nombre", "Jugador"),
		int(datos.get("nivel", 1)),
		int(datos.get("estrellas", 0)),
		monedas_totales,
		datos.get("mundo1_completado", false),
		secciones
	)

	_mostrar_resultado(monedas_ganadas, perfecta)

# ─────────────────────────────────────────────────────────────
#  PANTALLA DE RESULTADO
# ─────────────────────────────────────────────────────────────
func _mostrar_resultado(monedas: int, perfecta: bool) -> void:
	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").musica_victoria()
	var cel_script = load("res://scripts/celebracion.gd")
	cel_script.lanzar(get_tree().root)
	if mundo_completado_ahora:
		await get_tree().create_timer(0.8).timeout
		_mostrar_mundo_completo(monedas)
		return

	if has_node("PanelResultado"):
		$PanelResultado.visible = true
		if has_node("PanelResultado/LabelResultado"):
			if perfecta:
				$PanelResultado/LabelResultado.text = "¡PERFECTO!"
			else:
				$PanelResultado/LabelResultado.text = "¡SECCIÓN COMPLETA!"
		if has_node("PanelResultado/LabelBonus"):
			$PanelResultado/LabelBonus.text = "Ganaste ★ " + str(monedas) + " monedas"
		if has_node("PanelResultado/BtnContinuar"):
			if not $PanelResultado/BtnContinuar.pressed.is_connected(_volver_a_explorar):
				$PanelResultado/BtnContinuar.pressed.connect(_volver_a_explorar)
	else:
		await get_tree().create_timer(1.0).timeout
		_volver_a_explorar()

# ─────────────────────────────────────────────────────────────
#  PANTALLA DE MUNDO COMPLETO
# ─────────────────────────────────────────────────────────────
func _mostrar_mundo_completo(monedas: int) -> void:
	var llave_script = load("res://scripts/llave_animacion.gd")
	llave_script.mostrar(get_tree().root, "res://assets/ui/llaves/llave_mundo3.PNG",
		func(): _pantalla_mundo_completo(monedas))

func _pantalla_mundo_completo(monedas: int) -> void:
	var overlay = ColorRect.new()
	overlay.name = "OverlayMundoCompleto"
	overlay.color = Color(0.12, 0.04, 0.22, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Mati con su skin actual, mostrado en grande como campeon
	var skin_id = "default"
	var guardado_node_local = load("res://scripts/guardado.gd").new()
	skin_id = guardado_node_local.cargar().get("skin_activa", "default")
	var rutas_frente = {
		"default": "res://assets/personajes/mati_frente.PNG",
		"fachero": "res://assets/personajes/mati_fachero.PNG",
		"ninja":   "res://assets/personajes/mati_ninja.PNG",
		"escolar": "res://assets/personajes/mati_escolar.PNG",
		"joven":   "res://assets/personajes/mati_joven.PNG",
		"lentes":  "res://assets/personajes/mati_lentes.PNG",
	}
	var ruta_mati : String = rutas_frente.get(skin_id, rutas_frente["default"])
	var mati_img : TextureRect = null
	if ResourceLoader.exists(ruta_mati):
		mati_img = TextureRect.new()
		mati_img.texture = load(ruta_mati)
		mati_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mati_img.set_anchors_preset(Control.PRESET_CENTER)
		mati_img.position = Vector2(-110, -350)
		mati_img.size = Vector2(220, 240)
		mati_img.modulate.a = 0.0
		overlay.add_child(mati_img)

	var corona = Label.new()
	corona.text = "👑"
	corona.add_theme_font_size_override("font_size", 64)
	corona.set_anchors_preset(Control.PRESET_CENTER)
	corona.position = Vector2(-40, -400)
	corona.size = Vector2(80, 80)
	corona.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corona.modulate.a = 0.0
	overlay.add_child(corona)

	var titulo = Label.new()
	titulo.text = "¡MISION CUMPLIDA!"
	titulo.add_theme_font_size_override("font_size", 62)
	titulo.add_theme_color_override("font_color", Color(0.88, 0.55, 1.0))
	titulo.set_anchors_preset(Control.PRESET_CENTER)
	titulo.position = Vector2(-380, -100)
	titulo.size = Vector2(760, 90)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.pivot_offset = Vector2(380, 45)
	titulo.scale = Vector2(0.1, 0.1)
	titulo.modulate.a = 0.0
	overlay.add_child(titulo)

	var mensaje = Label.new()
	mensaje.text = "¡Lo lograste, Mati!\nCompletaste los 7 desafios del Planeta Hongos\ny demostraste que eres un campeon.\nGanaste ★ " + str(monedas) + " monedas.\n\n¡Eres un verdadero maestro\nde las multiplicaciones!"
	mensaje.add_theme_font_size_override("font_size", 28)
	mensaje.add_theme_color_override("font_color", Color(1, 1, 1))
	mensaje.set_anchors_preset(Control.PRESET_CENTER)
	mensaje.position = Vector2(-380, 20)
	mensaje.size = Vector2(760, 220)
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensaje.modulate.a = 0.0
	overlay.add_child(mensaje)

	var boton = Button.new()
	boton.text = "Ir al Mapa  →"
	boton.add_theme_font_size_override("font_size", 28)
	boton.set_anchors_preset(Control.PRESET_CENTER)
	boton.position = Vector2(-140, 260)
	boton.size = Vector2(280, 70)
	boton.modulate.a = 0.0
	boton.pressed.connect(_ir_al_mapa)
	overlay.add_child(boton)

	# Animación de entrada épica
	var tw := create_tween().set_parallel(false)
	tw.tween_property(overlay, "color", Color(0.12, 0.04, 0.22, 0.92), 0.4)
	if mati_img:
		tw.tween_property(mati_img, "modulate:a", 1.0, 0.3)
	tw.tween_property(corona, "modulate:a", 1.0, 0.25)
	tw.tween_property(titulo, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(titulo, "modulate:a", 1.0, 0.3)
	tw.tween_property(mensaje, "modulate:a", 1.0, 0.4)
	tw.tween_property(boton, "modulate:a", 1.0, 0.3)

func _ir_al_mapa() -> void:
	TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")

func _volver_a_explorar() -> void:
	TransitionManager.cambiar_escena("res://scenes/Mundo3Explorar.tscn")

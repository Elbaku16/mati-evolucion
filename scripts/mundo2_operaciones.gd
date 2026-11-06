extends Control

# ═══════════════════════════════════════════════════════════════
#  MUNDO 2 — PANTALLA DE OPERACIONES (PLANETA HIELO)
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
var seccion_actual  : int        = 6
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
	6:  { "tipo": "suma",       "max": 50 },
	7:  { "tipo": "resta",      "max": 50 },
	8:  { "tipo": "mult",       "tabla": 1 },
	9:  { "tipo": "mult",       "tabla": 2 },
	10: { "tipo": "mult_mixto", "max": 3  },
	20: { "tipo": "mixto",      "max": 50 },   # Desafío del robot ROBO-X (opcional, no bloquea progresión)
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
	seccion_actual = int(datos.get("seccion_actual", 6))
	config_seccion = SECCIONES.get(seccion_actual, SECCIONES[6])
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
		"suma":
			op = "+"
			var maximo = int(config_seccion.get("max", 50))
			num1 = randi_range(1, maximo - 1)
			num2 = randi_range(1, maximo - num1)
			respuesta = num1 + num2
		"resta":
			op = "-"
			var maximo = int(config_seccion.get("max", 50))
			num1 = randi_range(2, maximo)
			num2 = randi_range(1, num1 - 1)
			respuesta = num1 - num2
		"mult":
			op = "x"
			var tabla = int(config_seccion.get("tabla", 1))
			num1 = tabla
			num2 = randi_range(1, 9)
			respuesta = num1 * num2
		"mult_mixto":
			op = "x"
			var maximo = int(config_seccion.get("max", 3))
			num1 = randi_range(1, maximo)
			num2 = randi_range(1, 9)
			respuesta = num1 * num2
		"mixto":
			var maximo = int(config_seccion.get("max", 50))
			var sub_tipo = randi_range(0, 2)
			match sub_tipo:
				0:
					op = "+"
					num1 = randi_range(1, maximo - 1)
					num2 = randi_range(1, maximo - num1)
					respuesta = num1 + num2
				1:
					op = "-"
					num1 = randi_range(2, maximo)
					num2 = randi_range(1, num1 - 1)
					respuesta = num1 - num2
				2:
					op = "x"
					num1 = randi_range(1, 9)
					num2 = randi_range(1, 9)
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

	# Verificar si completó las 5 secciones del Mundo 2 (6-10)
	var todas_completas = true
	for i in range(6, 11):
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
			if not $PanelResultado/BtnContinuar.pressed.is_connected(_volver_a_secciones):
				$PanelResultado/BtnContinuar.pressed.connect(_volver_a_secciones)
	else:
		await get_tree().create_timer(1.0).timeout
		_volver_a_secciones()

# ─────────────────────────────────────────────────────────────
#  PANTALLA DE MUNDO COMPLETO
# ─────────────────────────────────────────────────────────────
func _mostrar_mundo_completo(monedas: int) -> void:
	var llave_script = load("res://scripts/llave_animacion.gd")
	llave_script.mostrar(get_tree().root, "res://assets/ui/llaves/llave_mundo2.PNG",
		func(): _pantalla_mundo_completo(monedas))

func _pantalla_mundo_completo(monedas: int) -> void:
	var overlay = ColorRect.new()
	overlay.name = "OverlayMundoCompleto"
	overlay.color = Color(0.05, 0.1, 0.25, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var cristales = Label.new()
	cristales.text = "❄️  ❄️  ❄️  ❄️  ❄️"
	cristales.add_theme_font_size_override("font_size", 36)
	cristales.set_anchors_preset(Control.PRESET_CENTER)
	cristales.position = Vector2(-380, -260)
	cristales.size = Vector2(760, 50)
	cristales.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cristales.modulate.a = 0.0
	overlay.add_child(cristales)

	var titulo = Label.new()
	titulo.text = "¡MUNDO 2 COMPLETO!"
	titulo.add_theme_font_size_override("font_size", 62)
	titulo.add_theme_color_override("font_color", Color(0.6, 0.9, 1))
	titulo.set_anchors_preset(Control.PRESET_CENTER)
	titulo.position = Vector2(-380, -190)
	titulo.size = Vector2(760, 90)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.pivot_offset = Vector2(380, 45)
	titulo.scale = Vector2(0.1, 0.1)
	titulo.modulate.a = 0.0
	overlay.add_child(titulo)

	var mensaje = Label.new()
	mensaje.text = "¡Increíble Mati!\nEl portal de hielo está encendido.\nGanaste ★ " + str(monedas) + " monedas.\n\n¡Sigue tu aventura!"
	mensaje.add_theme_font_size_override("font_size", 28)
	mensaje.add_theme_color_override("font_color", Color(1, 1, 1))
	mensaje.set_anchors_preset(Control.PRESET_CENTER)
	mensaje.position = Vector2(-380, -60)
	mensaje.size = Vector2(760, 200)
	mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensaje.modulate.a = 0.0
	overlay.add_child(mensaje)

	var boton = Button.new()
	boton.text = "Ir al Mapa  →"
	boton.add_theme_font_size_override("font_size", 28)
	boton.set_anchors_preset(Control.PRESET_CENTER)
	boton.position = Vector2(-130, 160)
	boton.size = Vector2(280, 70)
	boton.modulate.a = 0.0
	boton.pressed.connect(_ir_al_mapa)
	overlay.add_child(boton)

	# Animación de entrada
	var tw := create_tween().set_parallel(false)
	tw.tween_property(overlay, "color", Color(0.05, 0.1, 0.25, 0.92), 0.4)
	tw.tween_property(titulo, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(titulo, "modulate:a", 1.0, 0.25)
	tw.tween_property(cristales, "modulate:a", 1.0, 0.3)
	tw.tween_property(mensaje, "modulate:a", 1.0, 0.4)
	tw.tween_property(boton, "modulate:a", 1.0, 0.3)

func _ir_al_mapa() -> void:
	TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")

func _volver_a_secciones() -> void:
	TransitionManager.cambiar_escena("res://scenes/Mundo2Explorar.tscn")

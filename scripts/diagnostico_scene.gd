extends Control

var operaciones_node
var diagnostico_node
var guardado_node
var botones_valores = []
var pregunta_actual = {}
var numero_pregunta = 0

const OPERADORES = {
	"+": "res://assets/ui/op_suma.png",
	"-": "res://assets/ui/op_resta.png",
	"x": "res://assets/ui/op_mult (2).png"
}

const ESTRELLA_VACIA = "res://assets/ui/estrella_respuesta.png"

# Carga estrella por número (0-100)
func _ruta_estrella(n: int) -> String:
	return "res://assets/ui/estrellas/%d.png" % n

var _musica_activa : bool = true
var _btn_volumen   : TextureButton = null

func _ready() -> void:
	operaciones_node = load("res://scripts/operaciones.gd").new()
	diagnostico_node = load("res://scripts/diagnostico.gd").new()
	guardado_node = load("res://scripts/guardado.gd").new()
	diagnostico_node.iniciar(operaciones_node)

	# Mantener música del menú sonando
	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").reproducir("fondo")

	# Botón de volumen anclado a esquina inferior derecha
	var capa := CanvasLayer.new()
	capa.layer = 10
	add_child(capa)

	_btn_volumen = TextureButton.new()
	_btn_volumen.ignore_texture_size = true
	_btn_volumen.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var tex_vol := load("res://assets/ui/Botones Vector/volumen.png") as Texture2D
	if tex_vol:
		_btn_volumen.texture_normal = tex_vol
	_btn_volumen.layout_mode = 1
	_btn_volumen.size = Vector2(70, 70)
	_btn_volumen.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_volumen.offset_left   = -80.0
	_btn_volumen.offset_top    = -80.0
	_btn_volumen.offset_right  = -10.0
	_btn_volumen.offset_bottom = -10.0
	_btn_volumen.pressed.connect(_on_volumen_presionado)
	capa.add_child(_btn_volumen)

	$LabelN1.visible = false
	$LabelN2.visible = false
	$LabelRes.visible = false
	$LabelB0.visible = false
	$LabelB1.visible = false
	$LabelB2.visible = false
	$LabelB3.visible = false
	$LabelB4.visible = false
	$LabelB5.visible = false

	$Btn0.pressed.connect(_on_btn_presionado.bind(0))
	$Btn1.pressed.connect(_on_btn_presionado.bind(1))
	$Btn2.pressed.connect(_on_btn_presionado.bind(2))
	$Btn3.pressed.connect(_on_btn_presionado.bind(3))
	$Btn4.pressed.connect(_on_btn_presionado.bind(4))
	$Btn5.pressed.connect(_on_btn_presionado.bind(5))

	actualizar_progreso()
	mostrar_pregunta()

func actualizar_progreso() -> void:
	$BarraProgreso.texture = load("res://assets/ui/progreso_%d.png" % numero_pregunta)

func mostrar_pregunta() -> void:
	pregunta_actual = diagnostico_node.obtener_pregunta_actual()
	if pregunta_actual.is_empty():
		return

	var num1 = pregunta_actual["num1"]
	var num2 = pregunta_actual["num2"]
	var op   = pregunta_actual["operacion"]
	var res  = pregunta_actual["respuesta"]
	var tipo = pregunta_actual["tipo"]

	$Operador.texture = load(OPERADORES[op])
	# Mantener siempre la escala original de la escena y dejar que stretch llene el rect
	$Operador.scale        = Vector2(0.07568138, 0.08303241)
	$Operador.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	$Operador.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	match tipo:
		0:
			_cargar_numero($NumFaltante1, num1, false)
			_cargar_numero($NumFaltante2, num2, false)
			_cargar_numero($Respuesta,    res,  true)
		1:
			_cargar_numero($NumFaltante1, num1, true)
			_cargar_numero($NumFaltante2, num2, false)
			_cargar_numero($Respuesta,    res,  false)
		2:
			_cargar_numero($NumFaltante1, num1, false)
			_cargar_numero($NumFaltante2, num2, true)
			_cargar_numero($Respuesta,    res,  false)

	var correcta: int
	match tipo:
		0: correcta = res
		1: correcta = num1
		2: correcta = num2

	# Generar 6 opciones únicas cercanas a la correcta
	var opciones = [correcta]
	var intentos = 0
	while opciones.size() < 6 and intentos < 300:
		intentos += 1
		# Opciones cercanas al valor correcto para que sea retador
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

# ─────────────────────────────────────────────────────────────
#  CARGA DE NÚMERO EN NODO
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
#  RESPUESTA
# ─────────────────────────────────────────────────────────────
func _on_btn_presionado(indice: int) -> void:
	var elegido = botones_valores[indice]
	var tipo = pregunta_actual["tipo"]
	var correcta: int
	match tipo:
		0: correcta = pregunta_actual["respuesta"]
		1: correcta = pregunta_actual["num1"]
		2: correcta = pregunta_actual["num2"]

	var btns = [$Btn0,$Btn1,$Btn2,$Btn3,$Btn4,$Btn5]
	for b in btns:
		b.disabled = true

	if elegido == correcta:
		btns[indice].modulate = Color(0.3, 1, 0.3, 1)
		diagnostico_node.responder(pregunta_actual["respuesta"])
		numero_pregunta += 1
		actualizar_progreso()
		await get_tree().create_timer(0.6).timeout
		for b in btns:
			b.disabled = false
		if diagnostico_node.hay_mas_preguntas():
			mostrar_pregunta()
		else:
			_ir_al_nivel()
	else:
		btns[indice].modulate = Color(1, 0.3, 0.3, 1)
		# Mostrar correcta en verde
		for i in range(6):
			if botones_valores[i] == correcta:
				btns[i].modulate = Color(0.3, 1, 0.3, 1)
				break
		diagnostico_node.responder(-1)
		numero_pregunta += 1
		actualizar_progreso()
		await get_tree().create_timer(0.6).timeout
		for b in btns:
			b.disabled = false
		if diagnostico_node.hay_mas_preguntas():
			mostrar_pregunta()
		else:
			_ir_al_nivel()

func _ir_al_nivel() -> void:
	var nivel = diagnostico_node.obtener_nivel_resultado()
	guardado_node.guardar("Jugador", nivel, 0, 0, false)
	TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")

func _on_volumen_presionado() -> void:
	_musica_activa = not _musica_activa
	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").set_volumen(1.0 if _musica_activa else 0.0)
	if _btn_volumen:
		_btn_volumen.modulate = Color(1, 1, 1, 1) if _musica_activa else Color(0.5, 0.5, 0.5, 1)

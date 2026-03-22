extends Control

var operaciones = null
var diagnostico = null
var guardado = null

func _ready() -> void:
	operaciones = load("res://scripts/operaciones.gd").new()
	diagnostico = load("res://scripts/diagnostico.gd").new()
	guardado = load("res://scripts/guardado.gd").new()
	
	diagnostico.iniciar(operaciones)
	$Button.pressed.connect(_on_responder_presionado)
	mostrar_pregunta()

func mostrar_pregunta() -> void:
	var pregunta = diagnostico.obtener_pregunta_actual()
	$Label.text = "%d %s %d = ?" % [pregunta["num1"], pregunta["operacion"], pregunta["num2"]]
	$Label2.text = "Pregunta %d de 10" % (diagnostico.indice_actual + 1)
	$LineEdit.text = ""
	$LineEdit.grab_focus()

func _on_responder_presionado() -> void:
	if $LineEdit.text == "":
		return
	var respuesta = int($LineEdit.text)
	diagnostico.responder(respuesta)
	
	if diagnostico.hay_mas_preguntas():
		mostrar_pregunta()
	else:
		var nivel = diagnostico.obtener_nivel_resultado()
		guardado.guardar("Jugador", nivel, 0)
		get_tree().change_scene_to_file("res://scenes/Juego.tscn")

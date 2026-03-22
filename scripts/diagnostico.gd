extends Node

var preguntas: Array = []
var indice_actual: int = 0
var aciertos: int = 0
var operaciones_node: Node

func iniciar(op_node: Node) -> void:
	operaciones_node = op_node
	preguntas.clear()
	indice_actual = 0
	aciertos = 0
	# Genera 10 preguntas mixtas para el diagnostico
	for i in range(10):
		var nivel_random = randi_range(1, 3)
		preguntas.append(operaciones_node.generar_operacion(nivel_random))

func obtener_pregunta_actual() -> Dictionary:
	if indice_actual < preguntas.size():
		return preguntas[indice_actual]
	return {}

func responder(respuesta_usuario: int) -> bool:
	var correcta = preguntas[indice_actual]["respuesta"] == respuesta_usuario
	if correcta:
		aciertos += 1
	indice_actual += 1
	return correcta

func hay_mas_preguntas() -> bool:
	return indice_actual < preguntas.size()

func obtener_nivel_resultado() -> int:
	return operaciones_node.determinar_nivel(aciertos)

func obtener_aciertos() -> int:
	return aciertos

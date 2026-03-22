extends Node

# Genera una operacion matematica segun el nivel
func generar_operacion(nivel: int) -> Dictionary:
	var num1: int
	var num2: int
	var operacion: String
	var respuesta: int
	
	if nivel == 1:
		num1 = randi_range(1, 9)
		num2 = randi_range(1, 9)
		if randi_range(0, 1) == 0:
			operacion = "+"
			respuesta = num1 + num2
		else:
			# En nivel 1 el mayor siempre va primero (sin negativos)
			if num1 < num2:
				var temp = num1
				num1 = num2
				num2 = temp
			operacion = "-"
			respuesta = num1 - num2
	
	elif nivel == 2:
		num1 = randi_range(10, 99)
		num2 = randi_range(10, 99)
		if randi_range(0, 1) == 0:
			operacion = "+"
			respuesta = num1 + num2
		else:
			if num1 < num2:
				var temp = num1
				num1 = num2
				num2 = temp
			operacion = "-"
			respuesta = num1 - num2
	
	elif nivel == 3:
		num1 = randi_range(1, 10)
		num2 = randi_range(2, 9)
		operacion = "x"
		respuesta = num1 * num2
	
	return {
		"num1": num1,
		"num2": num2,
		"operacion": operacion,
		"respuesta": respuesta
	}

# Determina el nivel segun aciertos del diagnostico
func determinar_nivel(aciertos: int) -> int:
	if aciertos <= 4:
		return 1
	elif aciertos <= 7:
		return 2
	else:
		return 3

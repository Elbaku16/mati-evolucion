extends Node

# ═══════════════════════════════════════════════════════════════
#  OPERACIONES — versión 2
#
#  Niveles:
#  1 → Sumas y restas simples (resultados 0-18)
#  2 → Sumas y restas medias (resultados hasta 50)
#  3 → Multiplicaciones y operaciones difíciles (resultados hasta 81)
#
#  El diagnóstico usa niveles 1-3 mezclados para evaluar al niño
# ═══════════════════════════════════════════════════════════════

func generar_operacion(nivel: int) -> Dictionary:
	var num1: int
	var num2: int
	var operacion: String
	var respuesta: int
	var tipo = randi_range(0, 2)

	match nivel:
		1:
			# Sumas y restas simples — números 1-9, resultado hasta 18
			num1 = randi_range(1, 9)
			num2 = randi_range(1, 9)
			if randi_range(0, 1) == 0:
				operacion = "+"
				respuesta = num1 + num2
			else:
				if num1 < num2:
					var t = num1; num1 = num2; num2 = t
				operacion = "-"
				respuesta = num1 - num2

		2:
			# Sumas y restas medias — números hasta 40, resultado hasta 50
			num1 = randi_range(5, 40)
			num2 = randi_range(1, 20)
			if randi_range(0, 1) == 0:
				operacion = "+"
				respuesta = num1 + num2
			else:
				if num1 < num2:
					var t = num1; num1 = num2; num2 = t
				operacion = "-"
				respuesta = num1 - num2

		3:
			# Multiplicaciones y sumas difíciles — resultado hasta 81
			var tipo_op = randi_range(0, 2)
			if tipo_op == 0:
				# Multiplicación simple
				num1 = randi_range(2, 9)
				num2 = randi_range(2, 9)
				operacion = "x"
				respuesta = num1 * num2
			elif tipo_op == 1:
				# Suma difícil
				num1 = randi_range(20, 60)
				num2 = randi_range(10, 30)
				operacion = "+"
				respuesta = num1 + num2
				# Limitar a 100
				if respuesta > 100:
					num2 = 100 - num1
					respuesta = num1 + num2
			else:
				# Resta difícil
				num1 = randi_range(30, 80)
				num2 = randi_range(10, 30)
				if num1 < num2:
					var t = num1; num1 = num2; num2 = t
				operacion = "-"
				respuesta = num1 - num2
		_:
			# Fallback nivel 1
			num1 = randi_range(1, 9)
			num2 = randi_range(1, 9)
			operacion = "+"
			respuesta = num1 + num2

	return {
		"num1": num1,
		"num2": num2,
		"operacion": operacion,
		"respuesta": respuesta,
		"tipo": tipo
	}

func determinar_nivel(aciertos: int) -> int:
	if aciertos <= 4:
		return 1
	elif aciertos <= 7:
		return 2
	else:
		return 3

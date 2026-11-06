extends Node

# ═══════════════════════════════════════════════════════════════
#  SISTEMA DE MISIONES Y COLECCIONABLES
#
#  Uso (desde cualquier script):
#    var M = load("res://scripts/misiones.gd")
#    M.incrementar(id_mision, guardado_data, incremento)   → modifica datos en memoria
#    M.esta_completa(id_mision, guardado_data) → bool
#    M.get_progreso(id_mision, guardado_data)  → int
#    M.get_todas()                             → Array de dicts
#
#  El llamador debe guardar los datos modificados después de incrementar.
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
#  DEFINICIÓN DE MISIONES
#  tipo: "contador" | "flag"
#  recompensa_tipo: "monedas" | "estrellas" | "skin" | "acceso"
# ─────────────────────────────────────────────────────────────
const MISIONES : Array = [
	# ─── PLANETA 1 — Verde ────────────────────────────────────
	{
		"id":              "p1_cristales",
		"planeta":         1,
		"nombre":          "Colector de Cristales",
		"descripcion":     "Recoge 5 cristales de energía en el Planeta Verde.",
		"tipo":            "contador",
		"objetivo":        5,
		"recompensa_tipo": "monedas",
		"recompensa":      15,
		"icono":           "💎",
	},
	{
		"id":              "p1_puertas",
		"planeta":         1,
		"nombre":          "Descifrando Runas",
		"descripcion":     "Resuelve 3 puertas matemáticas en el Planeta Verde.",
		"tipo":            "contador",
		"objetivo":        3,
		"recompensa_tipo": "estrellas",
		"recompensa":      2,
		"icono":           "🔑",
	},
	{
		"id":              "p1_nave",
		"planeta":         1,
		"nombre":          "Mecánico Estelar",
		"descripcion":     "Repara la nave averiada en el Planeta Verde.",
		"tipo":            "flag",
		"objetivo":        1,
		"recompensa_tipo": "monedas",
		"recompensa":      20,
		"icono":           "🚀",
	},
	# ─── PLANETA 2 — Hielo ────────────────────────────────────
	{
		"id":              "p2_carrera",
		"planeta":         2,
		"nombre":          "Piloto de Hielo",
		"descripcion":     "Llega a la meta en la carrera del Planeta de Hielo.",
		"tipo":            "flag",
		"objetivo":        1,
		"recompensa_tipo": "monedas",
		"recompensa":      18,
		"icono":           "🏁",
	},
	{
		"id":              "p2_memoria",
		"planeta":         2,
		"nombre":          "Mente de Cristal",
		"descripcion":     "Completa el minijuego de memoria en el Planeta de Hielo.",
		"tipo":            "flag",
		"objetivo":        1,
		"recompensa_tipo": "estrellas",
		"recompensa":      3,
		"icono":           "🧊",
	},
	{
		"id":              "p2_monedas",
		"planeta":         2,
		"nombre":          "Tesorero Glacial",
		"descripcion":     "Recolecta 20 monedas en el Planeta de Hielo.",
		"tipo":            "contador",
		"objetivo":        20,
		"recompensa_tipo": "monedas",
		"recompensa":      25,
		"icono":           "🪙",
	},
	# ─── PLANETA 3 — Hongos ───────────────────────────────────
	{
		"id":              "p3_jefe",
		"planeta":         3,
		"nombre":          "Campeón de los Hongos",
		"descripcion":     "Derrota al jefe final del Planeta de los Hongos.",
		"tipo":            "flag",
		"objetivo":        1,
		"recompensa_tipo": "estrellas",
		"recompensa":      5,
		"icono":           "🍄",
	},
	{
		"id":              "p3_acertijos",
		"planeta":         3,
		"nombre":          "Mago de los Acertijos",
		"descripcion":     "Resuelve 5 acertijos mágicos en el Planeta de los Hongos.",
		"tipo":            "contador",
		"objetivo":        5,
		"recompensa_tipo": "monedas",
		"recompensa":      22,
		"icono":           "✨",
	},
	{
		"id":              "p3_construccion",
		"planeta":         3,
		"nombre":          "Restaurador de Portales",
		"descripcion":     "Reconstruye el portal roto en el Planeta de los Hongos.",
		"tipo":            "flag",
		"objetivo":        1,
		"recompensa_tipo": "monedas",
		"recompensa":      20,
		"icono":           "🌀",
	},
	# ─── GLOBALES ─────────────────────────────────────────────
	{
		"id":              "global_explorador",
		"planeta":         0,
		"nombre":          "Gran Explorador",
		"descripcion":     "Visita los 3 planetas.",
		"tipo":            "contador",
		"objetivo":        3,
		"recompensa_tipo": "estrellas",
		"recompensa":      5,
		"icono":           "🌌",
	},
	{
		"id":              "global_coleccionables",
		"planeta":         0,
		"nombre":          "Coleccionista Galáctico",
		"descripcion":     "Recoge 10 coleccionables en total.",
		"tipo":            "contador",
		"objetivo":        10,
		"recompensa_tipo": "monedas",
		"recompensa":      30,
		"icono":           "🏅",
	},
]

# ─────────────────────────────────────────────────────────────
#  COLECCIONABLES — tipos por planeta
# ─────────────────────────────────────────────────────────────
const COLECCIONABLES_TIPOS : Dictionary = {
	1: {"nombre": "Cristal Verde",   "icono": "💎", "color": Color(0.2, 1.0, 0.4)},
	2: {"nombre": "Fragmento Hielo", "icono": "🧊", "color": Color(0.4, 0.8, 1.0)},
	3: {"nombre": "Espora Mágica",   "icono": "🍄", "color": Color(0.9, 0.3, 1.0)},
}

# ─────────────────────────────────────────────────────────────
#  API ESTÁTICA
# ─────────────────────────────────────────────────────────────
static func get_todas() -> Array:
	return MISIONES

static func get_mision(id: String) -> Dictionary:
	for m in MISIONES:
		if m["id"] == id:
			return m
	return {}

static func esta_completa(id: String, datos: Dictionary) -> bool:
	var misiones_datos : Dictionary = datos.get("misiones", {})
	return bool(misiones_datos.get(id + "_completa", false))

static func get_progreso(id: String, datos: Dictionary) -> int:
	var misiones_datos : Dictionary = datos.get("misiones", {})
	return int(misiones_datos.get(id + "_prog", 0))

static func incrementar(id: String, datos: Dictionary, cantidad: int = 1) -> bool:
	# Retorna true si la misión se completó con este incremento
	var mision := get_mision(id)
	if mision.is_empty():
		return false
	if esta_completa(id, datos):
		return false

	if not datos.has("misiones"):
		datos["misiones"] = {}

	var prev  := get_progreso(id, datos)
	var nuevo := prev + cantidad
	datos["misiones"][id + "_prog"] = nuevo

	var objetivo := int(mision.get("objetivo", 1))
	if nuevo >= objetivo:
		datos["misiones"][id + "_completa"] = true
		# Aplicar recompensa en datos
		var tipo := mision.get("recompensa_tipo", "monedas")
		var valor := int(mision.get("recompensa", 0))
		match tipo:
			"monedas":
				datos["monedas"] = int(datos.get("monedas", 0)) + valor
			"estrellas":
				datos["estrellas"] = int(datos.get("estrellas", 0)) + valor
		return true
	return false

static func marcar_completa(id: String, datos: Dictionary) -> bool:
	return incrementar(id, datos, 999)

# Contador global de coleccionables
static func registrar_coleccionable(planeta: int, datos: Dictionary) -> void:
	# Coleccionables por planeta
	var key := "coleccionables_p%d" % planeta
	datos[key] = int(datos.get(key, 0)) + 1
	# Contador global
	var total := int(datos.get("coleccionables_total", 0)) + 1
	datos["coleccionables_total"] = total
	# Actualizar misión de cristales del planeta 1
	if planeta == 1:
		incrementar("p1_cristales", datos, 1)
	# Misión coleccionista global
	incrementar("global_coleccionables", datos, 1)

extends Node

# ═══════════════════════════════════════════════════════════════
#  SISTEMA DE HABILIDADES — Mati Evolución
#
#  Habilidades desbloqueables con monedas.
#  Se guardan en el save del jugador bajo la clave "habilidades".
#  No modifica el sistema de skins ni de tienda existente.
#
#  Uso:
#    var h = load("res://scripts/habilidades.gd").new()
#    h.esta_desbloqueada("rayo")       → bool
#    h.desbloquear("rayo")             → bool (true = OK, false = monedas insuficientes)
#    h.esta_activa("escudo")           → bool (si está en el loadout activo)
#    h.activar("escudo")               → void
#    h.desactivar("escudo")            → void
# ═══════════════════════════════════════════════════════════════

const HABILIDADES_CONFIG : Dictionary = {
	"rayo": {
		"nombre":      "Rayo Matemático",
		"descripcion": "En combate, reduce la vida del jefe al doble con el ataque especial.",
		"icono":       "res://assets/ui/Estrella con signo de X .PNG",
		"costo":       25,
		"efecto":      "doble_especial",
	},
	"escudo": {
		"nombre":      "Escudo Espacial",
		"descripcion": "En combate, absorbe el primer ataque del jefe sin perder vida.",
		"icono":       "res://assets/ui/Icono 3 vidas.PNG",
		"costo":       30,
		"efecto":      "bloquea_primer_daño",
	},
	"iman": {
		"nombre":      "Imán de Monedas",
		"descripcion": "En el minijuego, el radio de recolección aumenta un 50%.",
		"icono":       "res://assets/ui/Moneda (1).png",
		"costo":       20,
		"efecto":      "radio_recoleccion_x1_5",
	},
	"turbo": {
		"nombre":      "Turbo Espacial",
		"descripcion": "En el minijuego, Mati se mueve un 30% más rápido.",
		"icono":       "res://assets/ui/cohete.png",
		"costo":       15,
		"efecto":      "velocidad_x1_3",
	},
}

const ORDEN : Array = ["turbo", "iman", "rayo", "escudo"]

var _guardado = null

func _ready() -> void:
	_guardado = load("res://scripts/guardado.gd").new()

# ─────────────────────────────────────────────────────────────
#  CONSULTAS
# ─────────────────────────────────────────────────────────────
func esta_desbloqueada(id: String) -> bool:
	var datos := _guardado.cargar()
	var habs  : Array = datos.get("habilidades_desbloqueadas", [])
	return id in habs

func esta_activa(id: String) -> bool:
	var datos := _guardado.cargar()
	var activas : Array = datos.get("habilidades_activas", [])
	return id in activas

func get_config(id: String) -> Dictionary:
	return HABILIDADES_CONFIG.get(id, {})

func get_todas() -> Array:
	return ORDEN

# ─────────────────────────────────────────────────────────────
#  DESBLOQUEAR
# ─────────────────────────────────────────────────────────────
func desbloquear(id: String) -> bool:
	if not HABILIDADES_CONFIG.has(id):
		return false
	if esta_desbloqueada(id):
		return true  # ya la tiene

	var costo := int(HABILIDADES_CONFIG[id].get("costo", 999))
	var datos := _guardado.cargar()
	var monedas := int(datos.get("monedas", 0))

	if monedas < costo:
		return false

	datos["monedas"] = monedas - costo
	var habs : Array = datos.get("habilidades_desbloqueadas", [])
	habs.append(id)
	datos["habilidades_desbloqueadas"] = habs

	var archivo := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()
	return true

# ─────────────────────────────────────────────────────────────
#  ACTIVAR / DESACTIVAR (loadout)
# ─────────────────────────────────────────────────────────────
func activar(id: String) -> void:
	if not esta_desbloqueada(id):
		return
	var datos := _guardado.cargar()
	var activas : Array = datos.get("habilidades_activas", [])
	if not id in activas:
		activas.append(id)
	datos["habilidades_activas"] = activas
	var archivo := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

func desactivar(id: String) -> void:
	var datos := _guardado.cargar()
	var activas : Array = datos.get("habilidades_activas", [])
	activas.erase(id)
	datos["habilidades_activas"] = activas
	var archivo := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

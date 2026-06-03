extends Node

# ═══════════════════════════════════════════════════════════════
#  SISTEMA DE GUARDADO — MATI APRENDE
# ═══════════════════════════════════════════════════════════════

const RUTA : String = "user://mati_save.json"

# Guardar datos del jugador
# Preserva campos extras del save (como seccion_actual) que no estén en los parámetros
func guardar(
	nombre        : String,
	nivel         : int,
	estrellas     : int,
	monedas       : int = 0,
	mundo1_ok     : bool = false,
	secciones     : Dictionary = {}
) -> void:
	# Cargar datos existentes para preservar campos extras
	var datos_existentes = cargar()

	# Actualizar solo los campos que recibimos como parámetro
	datos_existentes["nombre"]            = nombre
	datos_existentes["nivel"]             = int(nivel)
	datos_existentes["estrellas"]         = int(estrellas)
	datos_existentes["monedas"]           = int(monedas)
	datos_existentes["mundo1_completado"] = mundo1_ok
	datos_existentes["secciones"]         = secciones

	# Escribir todo (incluyendo campos extras como seccion_actual)
	var archivo = FileAccess.open(RUTA, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_existentes))
		archivo.close()

# Cargar datos del jugador
func cargar() -> Dictionary:
	if not FileAccess.file_exists(RUTA):
		return {
			"nombre"            : "Jugador",
			"nivel"             : 1,
			"estrellas"         : 0,
			"monedas"           : 0,
			"mundo1_completado" : false,
			"secciones"         : {}
		}

	var archivo = FileAccess.open(RUTA, FileAccess.READ)
	var texto = archivo.get_as_text()
	archivo.close()

	var json = JSON.new()
	if json.parse(texto) != OK:
		return {}

	var datos = json.data

	# Asegurar que existan todas las llaves (para saves viejos)
	if not datos.has("monedas"):
		datos["monedas"] = 0
	if not datos.has("mundo1_completado"):
		datos["mundo1_completado"] = false
	if not datos.has("secciones"):
		datos["secciones"] = {}
	if not datos.has("skin_activa"):
		datos["skin_activa"] = "default"
	if not datos.has("skins_compradas"):
		datos["skins_compradas"] = ["default"]

	# Convertir números a enteros
	datos["monedas"]   = int(datos.get("monedas", 0))
	datos["nivel"]     = int(datos.get("nivel", 1))
	datos["estrellas"] = int(datos.get("estrellas", 0))

	return datos

# Guardar progreso de una sección específica
func guardar_seccion(id_seccion: int, completada: bool, perfecta: bool) -> void:
	var datos = cargar()
	var secciones = datos.get("secciones", {})

	var key = str(id_seccion)
	var anterior = secciones.get(key, {})
	var ya_perfecta = anterior.get("perfecta", false)

	secciones[key] = {
		"completada" : completada,
		"perfecta"   : perfecta or ya_perfecta
	}

	guardar(
		datos.get("nombre", "Jugador"),
		int(datos.get("nivel", 1)),
		int(datos.get("estrellas", 0)),
		int(datos.get("monedas", 0)),
		datos.get("mundo1_completado", false),
		secciones
	)

# Verifica si una sección está desbloqueada
func seccion_desbloqueada(id_seccion: int) -> bool:
	if id_seccion <= 1:
		return true
	var datos = cargar()
	var secciones = datos.get("secciones", {})
	var anterior = secciones.get(str(id_seccion - 1), {})
	return anterior.get("completada", false)

# Verifica si una sección está completada
func seccion_completada(id_seccion: int) -> bool:
	var datos = cargar()
	var secciones = datos.get("secciones", {})
	return secciones.get(str(id_seccion), {}).get("completada", false)

# Verifica si una sección está completada de forma perfecta
func seccion_perfecta(id_seccion: int) -> bool:
	var datos = cargar()
	var secciones = datos.get("secciones", {})
	return secciones.get(str(id_seccion), {}).get("perfecta", false)

# ─────────────────────────────────────────────────────────────
#  SISTEMA DE SKINS
# ─────────────────────────────────────────────────────────────

func obtener_skin_activa() -> String:
	var datos = cargar()
	return datos.get("skin_activa", "default")

func skin_comprada(skin_id: String) -> bool:
	if skin_id == "default":
		return true
	var datos = cargar()
	var compradas = datos.get("skins_compradas", ["default"])
	return skin_id in compradas

func activar_skin(skin_id: String) -> void:
	var datos = cargar()
	datos["skin_activa"] = skin_id
	var archivo = FileAccess.open(RUTA, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

func comprar_skin(skin_id: String, costo: int) -> bool:
	var datos = cargar()
	var monedas = int(datos.get("monedas", 0))
	if monedas < costo:
		return false
	var compradas = datos.get("skins_compradas", ["default"])
	if not skin_id in compradas:
		compradas.append(skin_id)
	datos["skins_compradas"] = compradas
	datos["monedas"] = monedas - costo
	var archivo = FileAccess.open(RUTA, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()
	return true

# Sumar monedas al total
func sumar_monedas(cantidad: int) -> void:
	var datos = cargar()
	var nuevas = int(datos.get("monedas", 0)) + int(cantidad)
	guardar(
		datos.get("nombre", "Jugador"),
		int(datos.get("nivel", 1)),
		int(datos.get("estrellas", 0)),
		nuevas,
		datos.get("mundo1_completado", false),
		datos.get("secciones", {})
	)

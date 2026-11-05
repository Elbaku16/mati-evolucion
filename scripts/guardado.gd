extends Node

# ═══════════════════════════════════════════════════════════════
#  SISTEMA DE GUARDADO — MATI APRENDE
#  Cada jugador tiene su propio archivo: save_[nombre].json
# ═══════════════════════════════════════════════════════════════

const RUTA_PERFIL_ACTUAL : String = "user://jugador_actual.json"

static func _ruta_save(nombre: String) -> String:
	# Limpia el nombre para usarlo como nombre de archivo
	var limpio := nombre.strip_edges().to_lower()
	limpio = limpio.replace(" ", "_")
	# Quita caracteres no seguros para nombre de archivo
	var resultado := ""
	for c in limpio:
		if c.unicode_at(0) in range(97, 123) or c.unicode_at(0) in range(48, 58) or c == "_":
			resultado += c
	if resultado.length() == 0:
		resultado = "jugador"
	return "user://save_%s.json" % resultado

static func guardar_perfil_actual(nombre: String) -> void:
	var arch := FileAccess.open(RUTA_PERFIL_ACTUAL, FileAccess.WRITE)
	if arch:
		arch.store_string(JSON.stringify({"nombre": nombre}))
		arch.close()

static func obtener_perfil_actual() -> String:
	if not FileAccess.file_exists(RUTA_PERFIL_ACTUAL):
		return "Jugador"
	var arch := FileAccess.open(RUTA_PERFIL_ACTUAL, FileAccess.READ)
	if not arch:
		return "Jugador"
	var json := JSON.new()
	if json.parse(arch.get_as_text()) != OK:
		return "Jugador"
	arch.close()
	return json.data.get("nombre", "Jugador")

# Ruta del save del jugador actual
func _ruta() -> String:
	return _ruta_save(obtener_perfil_actual())

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

	# Registrar primer acceso si no existe
	if not datos_existentes.has("primer_acceso"):
		datos_existentes["primer_acceso"] = int(Time.get_unix_time_from_system())
	datos_existentes["ultimo_acceso"] = int(Time.get_unix_time_from_system())

	# Escribir todo (incluyendo campos extras como seccion_actual)
	var archivo = FileAccess.open(_ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_existentes))
		archivo.close()

	# Sincronizar con Firebase si estamos en web
	_sync_firebase(datos_existentes)

# Cargar datos del jugador
func cargar() -> Dictionary:
	if not FileAccess.file_exists(_ruta()):
		# Migración: si existe el save viejo, usarlo y renombrarlo
		const RUTA_VIEJA = "user://mati_save.json"
		if FileAccess.file_exists(RUTA_VIEJA):
			var arch_viejo = FileAccess.open(RUTA_VIEJA, FileAccess.READ)
			if arch_viejo:
				var contenido = arch_viejo.get_as_text()
				arch_viejo.close()
				var arch_nuevo = FileAccess.open(_ruta(), FileAccess.WRITE)
				if arch_nuevo:
					arch_nuevo.store_string(contenido)
					arch_nuevo.close()
				# No borramos el viejo para no perder datos si algo falla
		else:
			return {
				"nombre"            : "Jugador",
				"nivel"             : 1,
				"estrellas"         : 0,
				"monedas"           : 0,
				"mundo1_completado" : false,
				"secciones"         : {}
			}

	var archivo = FileAccess.open(_ruta(), FileAccess.READ)
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
	var archivo = FileAccess.open(_ruta(), FileAccess.WRITE)
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
	var archivo = FileAccess.open(_ruta(), FileAccess.WRITE)
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

# ─────────────────────────────────────────────────────────────
#  SINCRONIZACIÓN FIREBASE (solo en exportación web)
# ─────────────────────────────────────────────────────────────
static func _sync_firebase(datos: Dictionary) -> void:
	if OS.get_name() != "Web":
		return

	var nombre  : String = datos.get("nombre", "jugador")
	var key     : String = nombre.strip_edges().to_lower()
	key = key.replace(" ", "_")

	# Calcular secciones completadas por mundo
	var secciones : Dictionary = datos.get("secciones", {})
	var m1_total  : int = 0
	var m2_total  : int = 0
	var m3_total  : int = 0
	for i in range(1,  6): if secciones.get(str(i), {}).get("completada", false): m1_total += 1
	for i in range(6, 11): if secciones.get(str(i), {}).get("completada", false): m2_total += 1
	for i in range(11,18): if secciones.get(str(i), {}).get("completada", false): m3_total += 1

	var payload : Dictionary = {
		"nombre":             nombre,
		"monedas":            int(datos.get("monedas", 0)),
		"mundo1_completado":  datos.get("mundo1_completado", false),
		"mundo1_secciones":   m1_total,
		"mundo2_secciones":   m2_total,
		"mundo3_secciones":   m3_total,
		"skin_activa":        datos.get("skin_activa", "default"),
		"primer_acceso":      int(datos.get("primer_acceso", 0)),
		"ultimo_acceso":      int(datos.get("ultimo_acceso", 0))
	}

	var json_str : String = JSON.stringify(payload)
	var url      : String = "https://mati-evolucion-default-rtdb.firebaseio.com/jugadores/" + key + ".json"

	JavaScriptBridge.eval("""
		(function() {
			try {
				fetch('%s', {
					method: 'PUT',
					body: JSON.stringify(%s),
					headers: { 'Content-Type': 'application/json' }
				});
			} catch(e) {}
		})();
	""" % [url, json_str])

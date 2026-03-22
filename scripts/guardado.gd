extends Node

const RUTA_GUARDADO = "user://progreso.json"

# Guarda el progreso del nino
func guardar(nombre: String, nivel: int, estrellas: int) -> void:
	var datos = {
		"nombre": nombre,
		"nivel": nivel,
		"estrellas": estrellas
	}
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

# Carga el progreso guardado
func cargar() -> Dictionary:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return {}
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo:
		var contenido = archivo.get_as_text()
		archivo.close()
		var resultado = JSON.parse_string(contenido)
		if resultado:
			return resultado
	return {}

# Borra el progreso (para nuevo juego)
func borrar() -> void:
	if FileAccess.file_exists(RUTA_GUARDADO):
		DirAccess.remove_absolute(RUTA_GUARDADO)

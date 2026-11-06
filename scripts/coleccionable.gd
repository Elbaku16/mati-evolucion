extends Node2D

# ═══════════════════════════════════════════════════════════════
#  COLECCIONABLE — objeto brillante en el mundo que Mati puede recoger
#
#  Uso:
#    var c = Node2D.new()
#    c.set_script(load("res://scripts/coleccionable.gd"))
#    c.position = Vector2(x, y)
#    c.configurar(planeta, id_guardado_key)
#    parent.add_child(c)
#
#  Al recogerlo: actualiza guardado, lanza efecto, se elimina.
# ═══════════════════════════════════════════════════════════════

var _planeta     : int    = 1
var _save_key    : String = ""   # clave única para evitar recolectar dos veces
var _color       : Color  = Color(0.3, 1.0, 0.5)
var _tiempo      : float  = 0.0
var _recogido    : bool   = false
var _radio_col   : float  = 40.0

func configurar(planeta: int, save_key: String) -> void:
	_planeta  = planeta
	_save_key = save_key

	var tipos := {
		1: Color(0.2, 1.0, 0.4),
		2: Color(0.4, 0.85, 1.0),
		3: Color(0.9, 0.3, 1.0),
	}
	_color = tipos.get(planeta, Color(1, 1, 0.3))

	# Verificar si ya fue recogido en esta partida
	if _save_key != "":
		var gd = load("res://scripts/guardado.gd").new()
		var datos := gd.cargar()
		var recogidos : Array = datos.get("coleccionables_ids", [])
		if _save_key in recogidos:
			queue_free()
			return

func _process(delta: float) -> void:
	if _recogido:
		return
	_tiempo += delta
	queue_redraw()
	_verificar_proximidad()

func _verificar_proximidad() -> void:
	var mati := get_tree().current_scene.get_node_or_null("Mati")
	if mati == null:
		return
	if global_position.distance_to(mati.global_position) < _radio_col:
		_recoger()

func _recoger() -> void:
	if _recogido:
		return
	_recogido = true

	var gd = load("res://scripts/guardado.gd").new()
	var datos := gd.cargar()

	# Marcar como recogido para no duplicar
	if _save_key != "":
		var recogidos : Array = datos.get("coleccionables_ids", [])
		if _save_key in recogidos:
			queue_free()
			return
		recogidos.append(_save_key)
		datos["coleccionables_ids"] = recogidos

	# Registrar en sistema de misiones
	load("res://scripts/misiones.gd").registrar_coleccionable(_planeta, datos)

	# Guardar
	var arch := FileAccess.open(gd._ruta(), FileAccess.WRITE)
	if arch:
		arch.store_string(JSON.stringify(datos))
		arch.close()

	# Efectos
	var efectos = load("res://scripts/efectos_ui.gd")
	if efectos:
		efectos.estrella_burst(get_tree().root, global_position, 6)
		efectos.moneda_flotante(get_tree().root, global_position, 0)
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx("moneda")

	# Animación de recogida: escalar a 0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(2.5, 2.5), 0.12)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.18)
	tw.tween_callback(queue_free)

func _draw() -> void:
	if _recogido:
		return
	var t   := _tiempo
	var bob := sin(t * 2.0) * 5.0
	var glow_a := 0.4 + 0.3 * sin(t * 4.0)

	# Halo exterior
	draw_circle(Vector2(0, bob), 22.0, Color(_color.r, _color.g, _color.b, glow_a * 0.4))

	# Cristal (rombo)
	var pts := PackedVector2Array([
		Vector2(0,  bob - 18),
		Vector2(13, bob - 2),
		Vector2(0,  bob + 14),
		Vector2(-13, bob - 2),
	])
	draw_colored_polygon(pts, Color(_color.r, _color.g, _color.b, 0.9))

	# Brillo interno (triángulo superior)
	var pts2 := PackedVector2Array([
		Vector2(0,  bob - 18),
		Vector2(13, bob - 2),
		Vector2(-13, bob - 2),
	])
	draw_colored_polygon(pts2, Color(1, 1, 1, 0.35))

	# Destello pulsante
	draw_circle(Vector2(-3, bob - 7), 4.0 + sin(t * 8) * 1.5, Color(1, 1, 1, 0.5))

	# Rotación (efecto visual de órbita)
	var ang := t * 1.5
	var rx  := cos(ang) * 20
	var ry  := sin(ang) * 8
	draw_circle(Vector2(rx, bob + ry), 3.5, Color(_color.r, _color.g, _color.b, 0.6))

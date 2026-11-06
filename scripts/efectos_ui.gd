extends Node

# ═══════════════════════════════════════════════════════════════
#  EFECTOS UI — utilidades estáticas de efectos audiovisuales
#
#  Todos los métodos son static y crean nodos temporales que se
#  auto-eliminan. No requieren instancia ni autoload.
#
#  Uso:
#    var E = load("res://scripts/efectos_ui.gd")
#    E.flash_correcto(get_tree().root)
#    E.explosion(get_tree().root, Vector2(640, 360))
#    E.sacudida(self)             ← en un Control o Node2D
#    E.zoom_jefe(nodo_contenedor) ← en el nodo que contiene la escena
# ═══════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
#  FLASH DE PANTALLA COMPLETA
# ─────────────────────────────────────────────────────────────

## Flash verde suave — respuesta correcta
static func flash_correcto(parent: Node) -> void:
	_flash_pantalla(parent, Color(0.1, 0.9, 0.2, 0.0), Color(0.1, 0.9, 0.2, 0.30), 0.08, 0.22)

## Flash rojo suave — respuesta incorrecta
static func flash_incorrecto(parent: Node) -> void:
	_flash_pantalla(parent, Color(0.9, 0.1, 0.1, 0.0), Color(0.9, 0.1, 0.1, 0.35), 0.07, 0.28)

## Flash dorado — estrella / victoria importante
static func flash_dorado(parent: Node) -> void:
	_flash_pantalla(parent, Color(1.0, 0.85, 0.1, 0.0), Color(1.0, 0.85, 0.1, 0.45), 0.06, 0.40)

## Flash blanco — transición especial / desbloqueo mundo
static func flash_blanco(parent: Node) -> void:
	_flash_pantalla(parent, Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), 0.12, 0.50)

static func _flash_pantalla(parent: Node, col_inicio: Color, col_pico: Color,
		t_entrada: float, t_salida: float) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 90
	parent.add_child(canvas)

	var rect := ColorRect.new()
	rect.color = col_inicio
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)

	var tw := parent.create_tween()
	tw.tween_property(rect, "color", col_pico, t_entrada)
	tw.tween_property(rect, "color", col_inicio, t_salida)
	tw.tween_callback(canvas.queue_free)

# ─────────────────────────────────────────────────────────────
#  SACUDIDA DE PANTALLA (screen shake suave)
#  Anima el offset de un CanvasLayer o la posición de un Control.
#  Intensidad recomendada: 4–8 para efectos normales.
# ─────────────────────────────────────────────────────────────
static func sacudida(nodo: Node, intensidad: float = 5.0, duracion: float = 0.3) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	var origen : Vector2 = Vector2.ZERO
	if nodo is CanvasLayer:
		origen = nodo.offset
	elif nodo is Control:
		origen = nodo.position
	elif nodo is Node2D:
		origen = nodo.position

	var pasos : int = int(duracion / 0.04)
	var tw := nodo.create_tween()
	for i in pasos:
		var fac := 1.0 - float(i) / float(pasos)
		var dx := randf_range(-intensidad, intensidad) * fac
		var dy := randf_range(-intensidad * 0.5, intensidad * 0.5) * fac
		var dest := origen + Vector2(dx, dy)
		if nodo is CanvasLayer:
			tw.tween_property(nodo, "offset", dest, 0.04)
		else:
			tw.tween_property(nodo, "position", dest, 0.04)
	# Restaurar posición original
	if nodo is CanvasLayer:
		tw.tween_property(nodo, "offset", origen, 0.05)
	else:
		tw.tween_property(nodo, "position", origen, 0.05)

# ─────────────────────────────────────────────────────────────
#  ZOOM DE JEFE — amplía el contenedor de la escena al presentar
#  Anima scale del nodo y vuelve a 1.0. Suave para niños.
# ─────────────────────────────────────────────────────────────
static func zoom_jefe(nodo: Node, escala_max: float = 1.06, duracion: float = 0.5) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	var tw := nodo.create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(nodo, "scale", Vector2(escala_max, escala_max), duracion * 0.4)
	tw.tween_property(nodo, "scale", Vector2(1.0, 1.0), duracion * 0.6)

# ─────────────────────────────────────────────────────────────
#  EXPLOSION — anillo expansivo + chispas, útil en ataques
# ─────────────────────────────────────────────────────────────
static func explosion(parent: Node, pos: Vector2,
		color: Color = Color(1.0, 0.65, 0.1), radio_max: float = 90.0) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 85
	parent.add_child(canvas)

	# Anillo exterior
	var anillo := _Anillo.new()
	anillo.position    = pos
	anillo.col         = color
	anillo.radio_max   = radio_max
	anillo.duracion    = 0.45
	canvas.add_child(anillo)

	# Partículas / chispas
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in 10:
		var chispa := _Chispa.new()
		chispa.position = pos
		chispa.col  = color.lerp(Color.WHITE, 0.3)
		chispa.vel  = Vector2(rng.randf_range(-160, 160),
		                       rng.randf_range(-200, -40))
		chispa.duracion = rng.randf_range(0.35, 0.60)
		canvas.add_child(chispa)

	# Auto-limpieza
	var t := parent.create_tween()
	t.tween_interval(0.7)
	t.tween_callback(canvas.queue_free)

# ─────────────────────────────────────────────────────────────
#  ESTRELLA BURST — destellos de estrella para recompensas
# ─────────────────────────────────────────────────────────────
static func estrella_burst(parent: Node, pos: Vector2, cantidad: int = 6) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 85
	parent.add_child(canvas)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in cantidad:
		var angulo := TAU * i / cantidad + rng.randf_range(-0.2, 0.2)
		var vel    := Vector2(cos(angulo), sin(angulo)) * rng.randf_range(90, 160)
		var chispa := _Chispa.new()
		chispa.position = pos
		chispa.col      = Color(1.0, 0.9, 0.1)
		chispa.vel      = vel
		chispa.radio    = rng.randf_range(5.0, 9.0)
		chispa.duracion = rng.randf_range(0.4, 0.65)
		canvas.add_child(chispa)

	# Flash dorado central
	var circulo := _Chispa.new()
	circulo.position = pos
	circulo.col      = Color(1.0, 0.95, 0.4, 0.8)
	circulo.radio    = 24.0
	circulo.vel      = Vector2.ZERO
	circulo.duracion = 0.30
	canvas.add_child(circulo)

	var t := parent.create_tween()
	t.tween_interval(0.75)
	t.tween_callback(canvas.queue_free)

# ─────────────────────────────────────────────────────────────
#  PORTAL — anillo giratorio que se expande al abrir un portal
# ─────────────────────────────────────────────────────────────
static func portal_abrir(parent: Node, pos: Vector2) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 85
	parent.add_child(canvas)

	# Anillo que sale de dentro hacia afuera
	for j in 3:
		var anillo := _Anillo.new()
		anillo.position  = pos
		anillo.col       = Color(0.4, 0.8, 1.0, 0.7 - j * 0.15)
		anillo.radio_max = 70.0 + j * 25.0
		anillo.radio_ini = 10.0
		anillo.duracion  = 0.5 + j * 0.12
		anillo.grosor    = 6.0 - j * 1.5
		canvas.add_child(anillo)

	var t := parent.create_tween()
	t.tween_interval(0.90)
	t.tween_callback(canvas.queue_free)

# ─────────────────────────────────────────────────────────────
#  DESBLOQUEO DE MUNDO — nova dorada expansiva
# ─────────────────────────────────────────────────────────────
static func mundo_desbloqueado(parent: Node, pos: Vector2) -> void:
	flash_dorado(parent)
	estrella_burst(parent, pos, 10)

	var canvas := CanvasLayer.new()
	canvas.layer = 86
	parent.add_child(canvas)

	var anillo := _Anillo.new()
	anillo.position  = pos
	anillo.col       = Color(1.0, 0.85, 0.1, 0.6)
	anillo.radio_max = 180.0
	anillo.radio_ini = 10.0
	anillo.duracion  = 0.65
	anillo.grosor    = 10.0
	canvas.add_child(anillo)

	var t := parent.create_tween()
	t.tween_interval(0.8)
	t.tween_callback(canvas.queue_free)

# ─────────────────────────────────────────────────────────────
#  MONEDA FLOTANTE — texto "+N" que sube y desvanece
# ─────────────────────────────────────────────────────────────
static func moneda_flotante(parent: Node, pos: Vector2, cantidad: int = 1) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 88
	parent.add_child(canvas)

	var lbl := Label.new()
	lbl.text = "+%d 🪙" % cantidad
	lbl.position = pos - Vector2(30, 20)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	lbl.modulate.a = 0.0
	canvas.add_child(lbl)

	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.15)
	tw.tween_property(lbl, "position:y", lbl.position.y - 55, 0.65).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(lbl, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(canvas.queue_free)

# ─────────────────────────────────────────────────────────────
#  CLASES INTERNAS DE DIBUJO
# ─────────────────────────────────────────────────────────────

class _Anillo extends Node2D:
	var col       : Color   = Color(1, 1, 1, 0.8)
	var radio_ini : float   = 2.0
	var radio_max : float   = 80.0
	var grosor    : float   = 5.0
	var duracion  : float   = 0.4
	var _t        : float   = 0.0

	func _process(delta: float) -> void:
		_t += delta / duracion
		queue_redraw()

	func _draw() -> void:
		var t2 : float = clamp(_t, 0.0, 1.0)
		var r  : float = lerpf(radio_ini, radio_max, t2)
		var alpha : float = (1.0 - t2) * col.a
		if alpha < 0.01:
			return
		var c : Color = col
		c.a = alpha
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, c, grosor)

class _Chispa extends Node2D:
	var col      : Color   = Color(1, 0.8, 0.1)
	var vel      : Vector2 = Vector2.ZERO
	var radio    : float   = 5.0
	var duracion : float   = 0.5
	var _t       : float   = 0.0

	func _process(delta: float) -> void:
		_t += delta / duracion
		position += vel * delta
		vel.y += 180.0 * delta   # gravedad suave
		queue_redraw()

	func _draw() -> void:
		var t2    : float = clamp(_t, 0.0, 1.0)
		var alpha : float = 1.0 - t2
		if alpha < 0.01:
			return
		var c : Color = col
		c.a = alpha
		var r : float = radio * (1.0 - t2 * 0.5)
		draw_circle(Vector2.ZERO, r, c)

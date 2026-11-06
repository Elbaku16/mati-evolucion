extends Node

# ═══════════════════════════════════════════════════════════════
#  CELEBRACIÓN — Confeti en pantalla completa
#  Uso:  Celebracion.lanzar(get_tree().root)
#  Dura ~2.8 segundos y se elimina solo. No bloquea el juego.
# ═══════════════════════════════════════════════════════════════

static func lanzar(parent: Node) -> void:
	# Sonido de fanfare si no está ya sonando
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx("fanfare")

	# CanvasLayer para dibujar por encima de todo
	var canvas := CanvasLayer.new()
	canvas.layer = 95
	parent.add_child(canvas)

	# Control que maneja el dibujo (tiene queue_redraw y _draw)
	var c := _Confeti.new()
	canvas.add_child(c)

# ─── Clase interna ─────────────────────────────────────────────
class _Confeti extends Control:
	const COLORES := [
		Color(1.00, 0.20, 0.20),   # rojo
		Color(0.20, 0.80, 0.30),   # verde
		Color(0.20, 0.50, 1.00),   # azul
		Color(1.00, 0.85, 0.10),   # amarillo
		Color(0.90, 0.25, 0.90),   # morado
		Color(1.00, 0.55, 0.10),   # naranja
		Color(0.15, 0.90, 0.90),   # cyan
	]

	var _piezas  : Array = []
	var _tiempo  : float = 0.0
	const DURACION : float = 2.8

	func _ready() -> void:
		# Ocupa toda la pantalla, sin bloquear clics
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_generar_piezas()

	func _generar_piezas() -> void:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for _i in range(80):
			_piezas.append({
				"x":    rng.randf_range(0.0, 1280.0),
				"y":    rng.randf_range(-200.0, -10.0),
				"vy":   rng.randf_range(260.0, 520.0),
				"vx":   rng.randf_range(-80.0, 80.0),
				"rot":  rng.randf_range(0.0, TAU),
				"rvel": rng.randf_range(-4.0, 4.0),
				"w":    rng.randf_range(8.0, 18.0),
				"h":    rng.randf_range(6.0, 13.0),
				"tipo": randi() % 3,
				"col":  COLORES[randi() % COLORES.size()],
				"life": rng.randf_range(0.0, 0.8),
			})

	func _process(delta: float) -> void:
		_tiempo += delta
		for p in _piezas:
			p["life"] = float(p["life"]) + delta
			p["y"]    = float(p["y"])  + float(p["vy"]) * delta
			p["x"]    = float(p["x"])  + float(p["vx"]) * delta
			p["rot"]  = float(p["rot"]) + float(p["rvel"]) * delta
			p["vy"]   = float(p["vy"]) * (1.0 + delta * 0.08)
		queue_redraw()
		if _tiempo >= DURACION:
			get_parent().queue_free()   # elimina el CanvasLayer completo

	func _draw() -> void:
		for p in _piezas:
			if float(p["life"]) <= 0.0:
				continue
			var t    : float = clamp(_tiempo / DURACION, 0.0, 1.0)
			var fade : float = 1.0 - clamp((t - 0.65) / 0.35, 0.0, 1.0)
			var col  : Color = p["col"] as Color
			col.a = fade
			if col.a < 0.05:
				continue

			var pos := Vector2(float(p["x"]), float(p["y"]))
			var w   : float = float(p["w"])
			var h   : float = float(p["h"])
			var rot : float = float(p["rot"])

			match int(p["tipo"]):
				0:   # Rectángulo rotado
					var pts := PackedVector2Array([
						Vector2(-w * 0.5, -h * 0.5),
						Vector2( w * 0.5, -h * 0.5),
						Vector2( w * 0.5,  h * 0.5),
						Vector2(-w * 0.5,  h * 0.5),
					])
					var rot_pts := PackedVector2Array()
					for pt in pts:
						rot_pts.append(pos + pt.rotated(rot))
					draw_colored_polygon(rot_pts, col)

				1:   # Círculo
					draw_circle(pos, w * 0.5, col)

				2:   # Triángulo
					var pts2 := PackedVector2Array([
						Vector2(0.0,      -h * 0.6),
						Vector2( w * 0.5,  h * 0.4),
						Vector2(-w * 0.5,  h * 0.4),
					])
					var rot_pts2 := PackedVector2Array()
					for pt in pts2:
						rot_pts2.append(pos + pt.rotated(rot))
					draw_colored_polygon(rot_pts2, col)

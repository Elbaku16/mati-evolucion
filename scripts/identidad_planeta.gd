extends Node

# ═══════════════════════════════════════════════════════════════
#  IDENTIDAD POR PLANETA — efectos ambientales únicos
#
#  Uso (desde _ready() de cada mundo):
#    load("res://scripts/identidad_planeta.gd").aplicar(1, self)
#    load("res://scripts/identidad_planeta.gd").aplicar(2, self)
#    load("res://scripts/identidad_planeta.gd").aplicar(3, self)
# ═══════════════════════════════════════════════════════════════

static func aplicar(planeta: int, mundo: Node) -> void:
	match planeta:
		1: _planeta_verde(mundo)
		2: _planeta_hielo(mundo)
		3: _planeta_hongos(mundo)

	# Registrar visita para misión global
	_registrar_visita(planeta)

static func _registrar_visita(planeta: int) -> void:
	var gd = load("res://scripts/guardado.gd").new()
	var datos := gd.cargar()
	var visitas : Array = datos.get("planetas_visitados", [])
	if not planeta in visitas:
		visitas.append(planeta)
		datos["planetas_visitados"] = visitas
		load("res://scripts/misiones.gd").incrementar("global_explorador", datos, 1)
		var arch := FileAccess.open(gd._ruta(), FileAccess.WRITE)
		if arch:
			arch.store_string(JSON.stringify(datos))
			arch.close()

# ─────────────────────────────────────────────────────────────
#  PLANETA 1 — VERDE  (luz cálida, partículas de flora)
# ─────────────────────────────────────────────────────────────
static func _planeta_verde(mundo: Node) -> void:
	# Overlay de luz verde suave
	var canvas := CanvasLayer.new()
	canvas.layer = -1
	mundo.add_child(canvas)

	var tinte := ColorRect.new()
	tinte.color = Color(0.1, 0.4, 0.05, 0.06)
	tinte.set_anchors_preset(Control.PRESET_FULL_RECT)
	tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tinte)

	# Partículas de flora — polvo verde flotante
	var flora := _FloraParticulas.new()
	flora.z_index = 2
	mundo.add_child(flora)

# ─────────────────────────────────────────────────────────────
#  PLANETA 2 — HIELO  (tinte azul frío, copos de nieve)
# ─────────────────────────────────────────────────────────────
static func _planeta_hielo(mundo: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 60
	mundo.add_child(canvas)

	# Overlay azul helado
	var tinte := ColorRect.new()
	tinte.color = Color(0.0, 0.1, 0.35, 0.10)
	tinte.set_anchors_preset(Control.PRESET_FULL_RECT)
	tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tinte)

	# Copos de nieve cayendo
	var nieve := _NieveParticulas.new()
	nieve.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(nieve)

	# Bruma fría en la parte baja de la pantalla
	var bruma := ColorRect.new()
	bruma.color = Color(0.5, 0.75, 1.0, 0.08)
	bruma.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bruma.offset_top    = -80.0
	bruma.offset_bottom = 0.0
	bruma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bruma)

# ─────────────────────────────────────────────────────────────
#  PLANETA 3 — HONGOS  (tinte magenta mágico, esporas flotantes)
# ─────────────────────────────────────────────────────────────
static func _planeta_hongos(mundo: Node) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 60
	mundo.add_child(canvas)

	# Overlay morado mágico
	var tinte := ColorRect.new()
	tinte.color = Color(0.25, 0.0, 0.3, 0.09)
	tinte.set_anchors_preset(Control.PRESET_FULL_RECT)
	tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(tinte)

	# Esporas mágicas flotando
	var esporas := _EsporasParticulas.new()
	esporas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(esporas)

	# Resplandor desde el suelo
	var glow := ColorRect.new()
	glow.color = Color(0.6, 0.0, 0.8, 0.07)
	glow.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	glow.offset_top    = -120.0
	glow.offset_bottom = 0.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(glow)

# ─────────────────────────────────────────────────────────────
#  CLASES INTERNAS — PARTÍCULAS PROCEDURALES
# ─────────────────────────────────────────────────────────────

class _FloraParticulas extends Node2D:
	var _pts : Array = []
	var _tiempo : float = 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new(); rng.randomize()
		for _i in 18:
			_pts.append({
				"x":     rng.randf_range(0, 1280),
				"y":     rng.randf_range(0, 720),
				"vy":    rng.randf_range(-18.0, -8.0),
				"vx":    rng.randf_range(-6.0, 6.0),
				"r":     rng.randf_range(2.0, 5.0),
				"fase":  rng.randf_range(0, TAU),
				"alpha": rng.randf_range(0.4, 0.9),
			})

	func _process(delta: float) -> void:
		_tiempo += delta
		for p in _pts:
			p["x"] = float(p["x"]) + float(p["vx"]) * delta
			p["y"] = float(p["y"]) + float(p["vy"]) * delta
			if float(p["y"]) < -20: p["y"] = 740.0
			if float(p["x"]) < -20: p["x"] = 1300.0
			if float(p["x"]) > 1300: p["x"] = -20.0
		queue_redraw()

	func _draw() -> void:
		for p in _pts:
			var a : float = float(p["alpha"]) * (0.5 + 0.4 * sin(_tiempo * 2.0 + float(p["fase"])))
			draw_circle(Vector2(float(p["x"]), float(p["y"])),
			            float(p["r"]), Color(0.3, 0.9, 0.2, a))

class _NieveParticulas extends Control:
	var _copos : Array = []
	var _tiempo : float = 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var rng := RandomNumberGenerator.new(); rng.randomize()
		for _i in 35:
			_copos.append({
				"x":    rng.randf_range(0, 1280),
				"y":    rng.randf_range(0, 720),
				"vy":   rng.randf_range(30.0, 80.0),
				"vx":   rng.randf_range(-15.0, 15.0),
				"r":    rng.randf_range(2.0, 6.0),
				"fase": rng.randf_range(0, TAU),
				"tipo": randi() % 2,   # 0=circulo, 1=copo 6 ramas
			})

	func _process(delta: float) -> void:
		_tiempo += delta
		for c in _copos:
			c["y"] = float(c["y"]) + float(c["vy"]) * delta
			c["x"] = float(c["x"]) + float(c["vx"]) * delta + sin(_tiempo + float(c["fase"])) * 12 * delta
			if float(c["y"]) > 740: c["y"] = -10.0
			if float(c["x"]) < -10: c["x"] = 1290.0
			if float(c["x"]) > 1290: c["x"] = -10.0
		queue_redraw()

	func _draw() -> void:
		for c in _copos:
			var pos := Vector2(float(c["x"]), float(c["y"]))
			var r   := float(c["r"])
			var a   : float = 0.6 + 0.3 * sin(_tiempo * 2 + float(c["fase"]))
			if int(c["tipo"]) == 0:
				draw_circle(pos, r, Color(0.8, 0.9, 1.0, a))
			else:
				# 6 ramas de copo
				for i in 6:
					var ang := TAU * float(i) / 6.0
					draw_line(pos, pos + Vector2(cos(ang), sin(ang)) * r * 1.6,
					          Color(0.85, 0.95, 1.0, a), 1.0)

class _EsporasParticulas extends Control:
	var _esporas : Array = []
	var _tiempo  : float = 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		var rng := RandomNumberGenerator.new(); rng.randomize()
		for _i in 25:
			_esporas.append({
				"x":    rng.randf_range(0, 1280),
				"y":    rng.randf_range(0, 720),
				"vy":   rng.randf_range(-25.0, -8.0),
				"vx":   rng.randf_range(-10.0, 10.0),
				"r":    rng.randf_range(2.5, 6.0),
				"fase": rng.randf_range(0, TAU),
				"hue":  rng.randf_range(0.7, 1.0),   # violeta-magenta
			})

	func _process(delta: float) -> void:
		_tiempo += delta
		for s in _esporas:
			s["y"] = float(s["y"]) + float(s["vy"]) * delta
			s["x"] = float(s["x"]) + float(s["vx"]) * delta + sin(_tiempo * 0.8 + float(s["fase"])) * 15 * delta
			if float(s["y"]) < -15: s["y"] = 735.0
			if float(s["x"]) < -15: s["x"] = 1295.0
			if float(s["x"]) > 1295: s["x"] = -15.0
		queue_redraw()

	func _draw() -> void:
		for s in _esporas:
			var pos := Vector2(float(s["x"]), float(s["y"]))
			var r   := float(s["r"])
			var a   : float = 0.4 + 0.4 * sin(_tiempo * 3.0 + float(s["fase"]))
			var h   : float = float(s["hue"])
			var col := Color.from_hsv(h, 0.8, 1.0, a)
			draw_circle(pos, r, col)
			# Halo exterior
			draw_arc(pos, r * 2.0, 0, TAU, 8, Color(col.r, col.g, col.b, a * 0.3), 1.5)

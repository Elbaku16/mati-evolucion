extends Node2D

# ═══════════════════════════════════════════════════════════════
#  EFECTOS AMBIENTALES — Partículas de hielo en el Planeta Hielo
#  Copos de nieve y cristales flotantes que caen suavemente.
# ═══════════════════════════════════════════════════════════════

# Franjas verticales donde se generan los copos (cubre todo el mundo)
const FRANJAS_X : Array = [-1700.0, -1100.0, -500.0, 100.0, 700.0,
                            1300.0,  1900.0,  2400.0]
const POR_FRANJA : int  = 7   # copos por franja

var tiempo    : float = 0.0
var particulas : Array = []

func _ready() -> void:
	z_index = 2   # encima del fondo, detrás de NPCs
	_inicializar_particulas()

# ─────────────────────────────────────────────────────────────
func _inicializar_particulas() -> void:
	for fx in FRANJAS_X:
		for _j in range(POR_FRANJA):
			_spawn(fx, true)

func _spawn(franja_x: float, random_y: bool) -> void:
	var paleta := [
		Color(1.00, 1.00, 1.00, 0.85),  # blanco puro
		Color(0.75, 0.92, 1.00, 0.80),  # celeste muy suave
		Color(0.60, 0.85, 1.00, 0.70),  # azul hielo
		Color(0.88, 0.97, 1.00, 0.75),  # blanco azulado
		Color(0.50, 0.80, 1.00, 0.65),  # cyan claro
	]
	# vel_y positiva → caen hacia abajo (nieve cayendo)
	particulas.append({
		"franja_x": franja_x,
		"pos":      Vector2(
						franja_x + randf_range(-280.0, 280.0),
						randf_range(150.0, 900.0) if random_y else 150.0
					),
		"vel_y":    randf_range(18.0, 42.0),   # cae lentamente
		"drift":    randf_range(-10.0, 10.0),  # balanceo horizontal
		"phase":    randf_range(0.0, TAU),
		"size":     randf_range(2.2, 6.0),
		"color":    paleta[randi() % paleta.size()],
		"life":     randf_range(0.0, 6.0) if random_y else 0.0,
		"max_life": randf_range(7.0, 14.0),
		"tipo":     randi() % 3,   # 0=círculo  1=copo de nieve  2=cristal
		"rot":      randf_range(0.0, TAU),     # rotación inicial del cristal
		"rot_vel":  randf_range(-0.8, 0.8),    # velocidad de giro
	})

# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	tiempo += delta
	var muertos : Array = []

	for i in range(particulas.size()):
		var p : Dictionary = particulas[i]
		p["life"]  = float(p["life"]) + delta
		p["rot"]   = float(p["rot"]) + float(p["rot_vel"]) * delta
		p["pos"]   = Vector2(
			float(p["pos"].x) + sin(tiempo * 0.5 + float(p["phase"])) * float(p["drift"]) * delta,
			float(p["pos"].y) + float(p["vel_y"]) * delta
		)

		# Muere si llega abajo del mundo o agota su vida
		if float(p["life"]) >= float(p["max_life"]) or float(p["pos"].y) > 1050.0:
			muertos.append(i)

	for i in range(muertos.size() - 1, -1, -1):
		var franja = particulas[muertos[i]]["franja_x"]
		particulas.remove_at(muertos[i])
		_spawn(franja, false)

	queue_redraw()

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	for p in particulas:
		var t     : float = float(p["life"]) / float(p["max_life"])
		# Fade in rápido, fade out suave al final
		var fade  : float = min(t * 5.0, 1.0) * (1.0 - t * t)
		var pulse : float = 1.0 + sin(tiempo * 3.5 + float(p["phase"])) * 0.15
		var sz    : float = float(p["size"]) * pulse

		var col : Color = p["color"] as Color
		col.a *= fade
		if col.a < 0.04:
			continue

		var pos : Vector2 = p["pos"]
		var rot : float   = float(p["rot"])

		match int(p["tipo"]):
			0:   # Copo simple (círculo con brillo)
				draw_circle(pos, sz, col)
				var col2 := col; col2.a *= 0.4
				draw_circle(pos, sz * 0.45, Color(1, 1, 1, col.a * 0.6))

			1:   # Copo de nieve clásico (6 líneas + diagonales)
				var col_linea := col; col_linea.a *= 0.75
				var ll := sz * 2.0
				# 3 ejes (0°, 60°, 120°)
				for arm in range(3):
					var ang = rot + arm * (PI / 3.0)
					var d   = Vector2(cos(ang), sin(ang)) * ll
					draw_line(pos - d, pos + d, col_linea, 1.1)
				# Núcleo
				draw_circle(pos, sz * 0.55, col)

			2:   # Cristal de hielo (rombo/diamante con bordes)
				var pts := PackedVector2Array()
				var nx := Vector2(cos(rot), sin(rot)) * sz * 2.2
				var ny := Vector2(cos(rot + PI * 0.5), sin(rot + PI * 0.5)) * sz * 1.2
				pts.append(pos + nx)
				pts.append(pos + ny)
				pts.append(pos - nx)
				pts.append(pos - ny)
				pts.append(pos + nx)  # cerrar
				draw_colored_polygon(PackedVector2Array([pts[0], pts[1], pts[2], pts[3]]), col)
				var col_borde := col; col_borde.a = min(col.a * 1.5, 1.0)
				draw_polyline(pts, col_borde, 0.8)

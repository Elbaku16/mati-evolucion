extends Node2D

# ═══════════════════════════════════════════════════════════════
#  EFECTOS AMBIENTALES — Partículas flotantes en el Planeta Verde
#  Añade vida al mundo sin necesitar imágenes extra.
# ═══════════════════════════════════════════════════════════════

# Zonas X donde se generan las partículas (distribuidas por el mundo extendido)
const ZONAS_X : Array = [-2100.0, -1300.0, -400.0, 300.0, 700.0,
                          1200.0,  1700.0,  2400.0, 3100.0]
const POR_ZONA : int  = 9   # partículas por zona

var tiempo : float = 0.0
var particulas : Array = []

func _ready() -> void:
	z_index = 2   # encima del fondo, detrás de NPCs
	_inicializar_particulas()

# ─────────────────────────────────────────────────────────────
func _inicializar_particulas() -> void:
	for zx in ZONAS_X:
		for _j in range(POR_ZONA):
			_spawn(zx, true)

func _spawn(zona_x: float, random_y: bool) -> void:
	var paleta := [
		Color(1.00, 0.92, 0.20, 0.80),  # dorado
		Color(0.35, 1.00, 0.45, 0.70),  # verde brillante
		Color(1.00, 1.00, 1.00, 0.65),  # blanco
		Color(0.45, 0.90, 1.00, 0.70),  # celeste
		Color(0.95, 0.50, 1.00, 0.65),  # lila
		Color(1.00, 0.65, 0.20, 0.70),  # naranja
	]
	particulas.append({
		"zona_x":   zona_x,
		"pos":      Vector2(
						zona_x + randf_range(-250.0, 250.0),
						randf_range(300.0, 860.0) if random_y else 870.0
					),
		"vel_y":    randf_range(-22.0, -8.0),
		"drift":    randf_range(-14.0, 14.0),
		"phase":    randf_range(0.0, TAU),
		"size":     randf_range(2.0, 5.8),
		"color":    paleta[randi() % paleta.size()],
		"life":     randf_range(0.0, 4.0) if random_y else 0.0,
		"max_life": randf_range(5.0, 10.0),
		"tipo":     randi() % 3,   # 0=círculo  1=estrella  2=diamante
	})

# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	tiempo += delta
	var muertos : Array = []

	for i in range(particulas.size()):
		var p : Dictionary = particulas[i]
		p["life"] = float(p["life"]) + delta
		p["pos"]  = Vector2(
			float(p["pos"].x) + sin(tiempo * 0.6 + float(p["phase"])) * float(p["drift"]) * delta,
			float(p["pos"].y) + float(p["vel_y"]) * delta
		)

		if float(p["life"]) >= float(p["max_life"]) or float(p["pos"].y) < 120.0:
			muertos.append(i)

	# Eliminar de atrás hacia adelante para no romper índices
	for i in range(muertos.size() - 1, -1, -1):
		var zona = particulas[muertos[i]]["zona_x"]
		particulas.remove_at(muertos[i])
		_spawn(zona, false)

	queue_redraw()

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	for p in particulas:
		var t     : float = float(p["life"]) / float(p["max_life"])
		var fade  : float = sin(t * PI)
		var pulse : float = 1.0 + sin(tiempo * 5.5 + float(p["phase"])) * 0.30
		var sz    : float = float(p["size"]) * pulse

		var col : Color = p["color"] as Color
		col.a *= fade
		if col.a < 0.03:
			continue

		match int(p["tipo"]):
			0:   # Círculo simple
				draw_circle(p["pos"], sz, col)

			1:   # Estrella (4 líneas)
				draw_circle(p["pos"], sz * 0.6, col)
				var lc := col; lc.a *= 0.55
				var ll := sz * 2.4
				draw_line(p["pos"] + Vector2(-ll, 0), p["pos"] + Vector2(ll, 0),  lc, 1.2)
				draw_line(p["pos"] + Vector2(0, -ll), p["pos"] + Vector2(0, ll),  lc, 1.2)
				var ld := ll * 0.65
				draw_line(p["pos"] + Vector2(-ld,-ld), p["pos"] + Vector2(ld,ld), lc, 0.9)
				draw_line(p["pos"] + Vector2(-ld, ld), p["pos"] + Vector2(ld,-ld),lc, 0.9)

			2:   # Diamante (cuatro triángulos)
				var pts := PackedVector2Array([
					p["pos"] + Vector2(0, -sz * 1.8),
					p["pos"] + Vector2(sz * 1.1, 0),
					p["pos"] + Vector2(0,  sz * 1.8),
					p["pos"] + Vector2(-sz * 1.1, 0),
				])
				draw_colored_polygon(pts, col)

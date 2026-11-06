extends Node2D

# ═══════════════════════════════════════════════════════════════
#  EFECTOS AMBIENTALES — Esporas flotantes del Planeta Hongos
#  Pequeñas partículas moradas que suben suavemente desde el suelo.
# ═══════════════════════════════════════════════════════════════

const FRANJAS_X : Array = [-1700.0, -1100.0, -500.0, 100.0, 700.0,
                            1300.0,  1900.0,  2400.0]
const POR_FRANJA : int  = 6   # esporas por franja

var tiempo    : float = 0.0
var particulas : Array = []

func _ready() -> void:
	z_index = 2   # encima del fondo, detrás de NPCs
	_inicializar_particulas()

func _inicializar_particulas() -> void:
	for fx in FRANJAS_X:
		for _j in range(POR_FRANJA):
			_spawn(fx, true)

func _spawn(franja_x: float, random_y: bool) -> void:
	var paleta := [
		Color(0.80, 0.42, 1.00, 0.80),  # morado brillante
		Color(0.95, 0.62, 1.00, 0.70),  # lila suave
		Color(0.62, 0.28, 0.88, 0.75),  # violeta profundo
		Color(1.00, 0.72, 1.00, 0.65),  # rosa-lila
		Color(0.72, 0.50, 1.00, 0.72),  # lavanda
		Color(0.88, 0.35, 0.95, 0.68),  # fucsia suave
	]
	# vel_y negativa → flotan hacia arriba (esporas subiendo)
	particulas.append({
		"franja_x": franja_x,
		"pos":      Vector2(
						franja_x + randf_range(-260.0, 260.0),
						randf_range(650.0, 1050.0) if random_y else 1050.0
					),
		"vel_y":    randf_range(-28.0, -12.0),   # sube lento
		"drift":    randf_range(-9.0, 9.0),       # balanceo
		"phase":    randf_range(0.0, TAU),
		"size":     randf_range(2.0, 5.5),
		"color":    paleta[randi() % paleta.size()],
		"life":     randf_range(0.0, 8.0) if random_y else 0.0,
		"max_life": randf_range(8.0, 16.0),
		"tipo":     randi() % 3,   # 0=punto  1=aro  2=estrella
		"rot":      randf_range(0.0, TAU),
		"rot_vel":  randf_range(-1.0, 1.0),
	})

func _process(delta: float) -> void:
	tiempo += delta
	var muertos : Array = []

	for i in range(particulas.size()):
		var p : Dictionary = particulas[i]
		p["life"]  = float(p["life"]) + delta
		p["rot"]   = float(p["rot"]) + float(p["rot_vel"]) * delta
		p["pos"]   = Vector2(
			float(p["pos"].x) + sin(tiempo * 0.45 + float(p["phase"])) * float(p["drift"]) * delta,
			float(p["pos"].y) + float(p["vel_y"]) * delta
		)
		# Muere si sube demasiado o agota su vida
		if float(p["life"]) >= float(p["max_life"]) or float(p["pos"].y) < 100.0:
			muertos.append(i)

	for i in range(muertos.size() - 1, -1, -1):
		var franja = particulas[muertos[i]]["franja_x"]
		particulas.remove_at(muertos[i])
		_spawn(franja, false)

	queue_redraw()

func _draw() -> void:
	for p in particulas:
		var t     : float = float(p["life"]) / float(p["max_life"])
		# Fade in rápido, fade out suave
		var fade  : float = min(t * 5.0, 1.0) * (1.0 - t * t)
		var pulse : float = 1.0 + sin(tiempo * 2.8 + float(p["phase"])) * 0.16
		var sz    : float = float(p["size"]) * pulse

		var col : Color = p["color"] as Color
		col.a *= fade
		if col.a < 0.04:
			continue

		var pos : Vector2 = p["pos"]
		var rot : float   = float(p["rot"])

		match int(p["tipo"]):
			0:   # Espora simple (punto brillante)
				draw_circle(pos, sz, col)
				draw_circle(pos, sz * 0.48, Color(1.0, 0.92, 1.0, col.a * 0.65))

			1:   # Aro de espora (anillo)
				draw_arc(pos, sz * 1.5, 0.0, TAU, 14,
					Color(col.r, col.g, col.b, col.a * 0.80), 1.0)
				draw_circle(pos, sz * 0.42, col)

			2:   # Partícula en forma de estrella de 4 puntas
				var col2 := col; col2.a *= 0.90
				for arm in range(4):
					var ang : float = rot + arm * (PI * 0.5)
					var d := Vector2(cos(ang), sin(ang)) * sz * 1.8
					draw_line(pos - d, pos + d, col2, 0.9)
				draw_circle(pos, sz * 0.55, col)

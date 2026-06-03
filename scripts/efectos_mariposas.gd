extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MARIPOSAS — Criaturas aladas que vuelan por el Planeta Verde.
#  Cada una vuela hacia un destino aleatorio con un suave bamboleo.
# ═══════════════════════════════════════════════════════════════

const N_MARIPOSAS : int = 20

var mariposas : Array = []
var tiempo    : float = 0.0

func _ready() -> void:
	z_index = 1
	for _i in range(N_MARIPOSAS):
		_spawn(true)

# ─────────────────────────────────────────────────────────────
func _spawn(_random_pos: bool) -> void:
	var paleta := [
		Color(1.00, 0.45, 0.75, 0.90),  # rosa fuerte
		Color(0.40, 0.85, 1.00, 0.90),  # celeste brillante
		Color(0.95, 1.00, 0.30, 0.90),  # amarillo-verde
		Color(1.00, 0.65, 0.15, 0.90),  # naranja vivo
		Color(0.75, 0.35, 1.00, 0.90),  # violeta
		Color(0.25, 1.00, 0.55, 0.90),  # verde menta
		Color(1.00, 0.85, 0.20, 0.90),  # dorado
	]
	var col_pri : Color = paleta[randi() % paleta.size()]
	# Variante más clara para el ala trasera (misma tonalidad, menos saturación)
	var col_sec : Color = Color.from_hsv(col_pri.h, clampf(col_pri.s - 0.25, 0.0, 1.0), 1.0, 0.65)

	var sx : float = randf_range(-2300.0, 3400.0)
	var sy : float = randf_range(260.0,  920.0)

	mariposas.append({
		"pos":        Vector2(sx, sy),
		"dest":       Vector2(randf_range(-2300.0, 3400.0), randf_range(260.0, 920.0)),
		"speed":      randf_range(55.0, 110.0),
		"phase":      randf_range(0.0, TAU),
		"flap_freq":  randf_range(7.0, 14.0),
		"wobble_amp": randf_range(20.0, 50.0),
		"wobble_frq": randf_range(1.5, 3.5),
		"size":       randf_range(6.0, 11.0),
		"col_pri":    col_pri,
		"col_sec":    col_sec,
	})

# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	tiempo += delta

	for m in mariposas:
		var mpos  : Vector2 = m["pos"]
		var mdest : Vector2 = m["dest"]
		var dir   : Vector2 = mdest - mpos
		var dist  : float   = dir.length()

		if dist < 35.0:
			# Nuevo destino cuando se acerca
			m["dest"] = Vector2(
				randf_range(-2300.0, 3400.0),
				randf_range(260.0, 920.0)
			)
			continue

		dir = dir / dist   # normalizar

		# Bamboleo perpendicular al vuelo
		var perp   : Vector2 = Vector2(-dir.y, dir.x)
		var wobble : Vector2 = perp * sin(tiempo * float(m["wobble_frq"]) + float(m["phase"])) * float(m["wobble_amp"])
		m["pos"] = mpos + (dir * float(m["speed"]) + wobble) * delta

	queue_redraw()

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	for m in mariposas:
		var pos     : Vector2 = m["pos"]
		var dest    : Vector2 = m["dest"]
		var sz      : float   = float(m["size"])
		var col_pri : Color   = m["col_pri"]
		var col_sec : Color   = m["col_sec"]

		# Dirección de vuelo
		var raw_dir : Vector2 = dest - pos
		var dir     : Vector2
		if raw_dir.length() > 1.0:
			dir = raw_dir.normalized()
		else:
			dir = Vector2(1.0, 0.0)
		var perp : Vector2 = Vector2(-dir.y, dir.x)

		# Apertura del ala: varía entre 0.3 y 1.0 con el tiempo
		var flap_t  : float = (sin(tiempo * float(m["flap_freq"]) + float(m["phase"])) * 0.5 + 0.5)
		var wing_w  : float = sz * 2.0 * flap_t + sz * 0.5
		var wing_h  : float = sz * 1.6

		# Ala trasera (izquierda/derecha, un poco más pequeña)
		var back_l := PackedVector2Array([
			pos,
			pos - perp * wing_w * 0.65 + dir * wing_h * 0.4,
			pos - perp * wing_w * 0.40 - dir * wing_h * 0.8,
		])
		var back_r := PackedVector2Array([
			pos,
			pos + perp * wing_w * 0.65 + dir * wing_h * 0.4,
			pos + perp * wing_w * 0.40 - dir * wing_h * 0.8,
		])
		draw_colored_polygon(back_l, col_sec)
		draw_colored_polygon(back_r, col_sec)

		# Ala delantera (más grande)
		var front_l := PackedVector2Array([
			pos,
			pos - perp * wing_w + dir * wing_h * 0.6,
			pos - perp * wing_w * 0.5 - dir * wing_h * 0.5,
		])
		var front_r := PackedVector2Array([
			pos,
			pos + perp * wing_w + dir * wing_h * 0.6,
			pos + perp * wing_w * 0.5 - dir * wing_h * 0.5,
		])
		draw_colored_polygon(front_l, col_pri)
		draw_colored_polygon(front_r, col_pri)

		# Cuerpo central (óvalo pequeño oscuro)
		draw_circle(pos, sz * 0.30, Color(0.08, 0.04, 0.0, 0.92))
		draw_circle(pos + dir * sz * 0.55, sz * 0.20, Color(0.08, 0.04, 0.0, 0.80))

		# Antenas (dos líneas finas)
		var ant_len : float = sz * 0.8
		draw_line(pos, pos + dir * ant_len - perp * ant_len * 0.5, Color(0.1, 0.05, 0.0, 0.7), 0.9)
		draw_line(pos, pos + dir * ant_len + perp * ant_len * 0.5, Color(0.1, 0.05, 0.0, 0.7), 0.9)
		# Puntito en la punta de la antena
		draw_circle(pos + dir * ant_len - perp * ant_len * 0.5, sz * 0.15, col_pri)
		draw_circle(pos + dir * ant_len + perp * ant_len * 0.5, sz * 0.15, col_pri)

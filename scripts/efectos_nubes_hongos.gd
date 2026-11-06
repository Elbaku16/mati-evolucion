extends "res://scripts/efectos_nubes.gd"

# ═══════════════════════════════════════════════════════════════
#  SETAS FLOTANTES
#  Reemplaza las nubes redondas por pequeños hongos/setas moradas
#  que derivan suavemente por el cielo del Planeta Hongos.
# ═══════════════════════════════════════════════════════════════

func _draw_nube(cx: float, cy: float, r: float, a: float) -> void:
	var w : float = r * 2.0   # ancho del sombrero
	var h : float = r * 0.75  # alto del sombrero

	# ── Tallo ─────────────────────────────────────────────────
	var c_tallo := Color(0.62, 0.35, 0.78, a * 0.65)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - r * 0.18, cy + h * 0.55),
		Vector2(cx + r * 0.18, cy + h * 0.55),
		Vector2(cx + r * 0.13, cy + h * 1.05),
		Vector2(cx - r * 0.13, cy + h * 1.05),
	]), c_tallo)

	# ── Láminas / cara inferior del sombrero ──────────────────
	var c_bajo := Color(0.42, 0.20, 0.62, a * 0.80)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.50, cy + h * 0.18),
		Vector2(cx + w * 0.50, cy + h * 0.18),
		Vector2(cx + w * 0.38, cy + h * 0.56),
		Vector2(cx - w * 0.38, cy + h * 0.56),
	]), c_bajo)

	# ── Sombrero principal (semicírculo) ──────────────────────
	var c_cap := Color(0.62, 0.28, 0.90, a * 0.92)
	var cap_pts := PackedVector2Array()
	var steps := 14
	for i in range(steps + 1):
		var ang : float = PI + (PI * float(i) / float(steps))
		cap_pts.append(Vector2(cx + cos(ang) * w * 0.50, cy + sin(ang) * h * 0.85))
	cap_pts.append(Vector2(cx + w * 0.50, cy + h * 0.18))
	cap_pts.append(Vector2(cx - w * 0.50, cy + h * 0.18))
	draw_colored_polygon(cap_pts, c_cap)

	# ── Ribete inferior (borde más claro) ─────────────────────
	var c_rim := Color(0.82, 0.58, 1.00, a * 0.78)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - w * 0.50, cy + h * 0.18),
		Vector2(cx - w * 0.36, cy + h * 0.50),
		Vector2(cx + w * 0.36, cy + h * 0.50),
		Vector2(cx + w * 0.50, cy + h * 0.18),
	]), c_rim)

	# ── Manchas blancas sobre el sombrero ─────────────────────
	var c_spot := Color(0.95, 0.82, 1.00, a * 0.65)
	draw_circle(Vector2(cx - r * 0.32, cy - h * 0.22), r * 0.11, c_spot)
	draw_circle(Vector2(cx + r * 0.12, cy - h * 0.38), r * 0.09, c_spot)
	draw_circle(Vector2(cx + r * 0.40, cy - h * 0.08), r * 0.10, c_spot)
	draw_circle(Vector2(cx - r * 0.05, cy - h * 0.55), r * 0.07, c_spot)

	# ── Brillo en la cima ──────────────────────────────────────
	draw_circle(
		Vector2(cx - r * 0.08, cy - h * 0.48),
		r * 0.22,
		Color(0.95, 0.80, 1.00, a * 0.40)
	)
	# Destello puntual
	draw_circle(
		Vector2(cx + r * 0.18, cy - h * 0.58),
		r * 0.08,
		Color(1.0, 0.95, 1.0, a * 0.75)
	)

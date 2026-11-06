extends "res://scripts/efectos_nubes.gd"

# ═══════════════════════════════════════════════════════════════
#  FRAGMENTOS DE HIELO FLOTANTES
#  Reemplaza las nubes redondas por bloques angulares de glaciar
#  que derivan lentamente por el cielo del Planeta Hielo.
# ═══════════════════════════════════════════════════════════════

func _draw_nube(cx: float, cy: float, r: float, a: float) -> void:
	var w  : float = r * 2.6   # ancho del fragmento
	var h  : float = r * 0.80  # alto  del fragmento (plano, como iceberg)

	# ── Capa 1: cara inferior/sombra (azul oscuro glacial) ─────
	var c_sombra := Color(0.38, 0.68, 0.88, a * 0.78)
	var sombra := PackedVector2Array([
		Vector2(cx - w * 0.50, cy + h * 0.55),
		Vector2(cx + w * 0.50, cy + h * 0.55),
		Vector2(cx + w * 0.50, cy + h * 0.08),
		Vector2(cx - w * 0.50, cy + h * 0.08),
	])
	draw_colored_polygon(sombra, c_sombra)

	# ── Capa 2: cara principal con silueta irregular de iceberg ─
	var c_cara := Color(0.78, 0.93, 1.00, a * 0.88)
	var cara := PackedVector2Array([
		Vector2(cx - w * 0.50, cy + h * 0.10),
		Vector2(cx - w * 0.44, cy - h * 0.08),
		Vector2(cx - w * 0.28, cy - h * 0.42),
		Vector2(cx - w * 0.06, cy - h * 0.55),
		Vector2(cx + w * 0.14, cy - h * 0.38),
		Vector2(cx + w * 0.30, cy - h * 0.60),
		Vector2(cx + w * 0.44, cy - h * 0.22),
		Vector2(cx + w * 0.50, cy + h * 0.10),
	])
	draw_colored_polygon(cara, c_cara)

	# ── Capa 3: faceta iluminada (zona central más clara) ──────
	var c_faceta := Color(0.90, 0.98, 1.00, a * 0.72)
	var faceta := PackedVector2Array([
		Vector2(cx - w * 0.06, cy + h * 0.05),
		Vector2(cx - w * 0.02, cy - h * 0.48),
		Vector2(cx + w * 0.14, cy - h * 0.34),
		Vector2(cx + w * 0.12, cy + h * 0.05),
	])
	draw_colored_polygon(faceta, c_faceta)

	# ── Pico izquierdo (más brillante) ─────────────────────────
	var c_pico := Color(1.00, 1.00, 1.00, a * 0.60)
	var pico := PackedVector2Array([
		Vector2(cx - w * 0.32, cy - h * 0.28),
		Vector2(cx - w * 0.28, cy - h * 0.45),
		Vector2(cx - w * 0.12, cy - h * 0.30),
		Vector2(cx - w * 0.10, cy - h * 0.10),
	])
	draw_colored_polygon(pico, c_pico)

	# ── Pico derecho (brillo especular) ────────────────────────
	var pico2 := PackedVector2Array([
		Vector2(cx + w * 0.26, cy - h * 0.40),
		Vector2(cx + w * 0.30, cy - h * 0.62),
		Vector2(cx + w * 0.40, cy - h * 0.28),
	])
	draw_colored_polygon(pico2, Color(1.00, 1.00, 1.00, a * 0.50))

	# ── Aristas del bloque (líneas de cristal) ──────────────────
	var c_arista := Color(0.68, 0.90, 1.00, a * 0.45)
	draw_line(
		Vector2(cx - w * 0.50, cy + h * 0.10),
		Vector2(cx - w * 0.06, cy - h * 0.55),
		c_arista, 1.1
	)
	draw_line(
		Vector2(cx + w * 0.50, cy + h * 0.10),
		Vector2(cx + w * 0.30, cy - h * 0.60),
		c_arista, 1.1
	)
	draw_line(
		Vector2(cx - w * 0.06, cy - h * 0.55),
		Vector2(cx + w * 0.30, cy - h * 0.60),
		Color(0.80, 0.95, 1.00, a * 0.30), 0.8
	)

	# ── Destellos puntuales (brillo de sol sobre hielo) ─────────
	draw_circle(
		Vector2(cx + w * 0.30, cy - h * 0.64),
		r * 0.09,
		Color(1.0, 1.0, 1.0, a * 0.90)
	)
	draw_circle(
		Vector2(cx - w * 0.06, cy - h * 0.58),
		r * 0.07,
		Color(1.0, 1.0, 1.0, a * 0.70)
	)

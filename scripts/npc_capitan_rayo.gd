extends Node2D

# ═══════════════════════════════════════════════════════════════
#  NPC CAPITÁN RAYO — Dibujado 100 % con código, sin imagen.
#  Misma interfaz que npc_personaje.gd (setup / marcar_completado)
# ═══════════════════════════════════════════════════════════════

const DISPLAY_W : float = 200.0
const DISPLAY_H : float = 240.0

var completado : bool  = false
var tiempo     : float = 0.0   # reloj para animaciones

# setup() existe para mantener la misma interfaz; no necesita textura
func setup(_tex) -> void:
	queue_redraw()

func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()   # redibujar cada frame para animar el rayo

func marcar_completado(val: bool) -> void:
	completado = val
	queue_redraw()

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var alpha : float = 0.40 if completado else 1.0
	draw_ellipse_shadow()
	_draw_character(alpha)
	if completado:
		_dibujar_check()

# ─────────────────────────────────────────────────────────────
#  PERSONAJE PROCEDURAL — CAPITÁN RAYO
# ─────────────────────────────────────────────────────────────
func _draw_character(a: float) -> void:
	# ── Pulso del rayo (anima con el tiempo) ────────────────
	var pulse : float = absf(sin(tiempo * 3.8))                # 0 → 1 → 0 …

	# ── Paleta ──────────────────────────────────────────────
	var navy  := Color(0.10, 0.15, 0.42, a)
	var blue  := Color(0.20, 0.32, 0.72, a)
	var gold  := Color(1.00, 0.72 + 0.13 * pulse, 0.08 * pulse, a)  # pulsante
	var skin  := Color(0.96, 0.78, 0.60, a)
	var dark  := Color(0.06, 0.08, 0.22, a)
	var red   := Color(0.82, 0.12, 0.12, a)
	var shine := Color(1.00, 1.00, 0.65, a * 0.45)

	# ── CAPA (detrás del cuerpo) ─────────────────────────────
	var cape := PackedVector2Array([
		Vector2(12, -86), Vector2(27, -86),
		Vector2(31, -52), Vector2(24, -22),
		Vector2(14, -32), Vector2(16, -62),
	])
	draw_colored_polygon(cape, red)

	# ── BOTAS ────────────────────────────────────────────────
	draw_rect(Rect2(-21, -20, 17, 20), dark)
	draw_rect(Rect2( 4,  -20, 17, 20), dark)
	# reflejo en botas
	draw_rect(Rect2(-20, -18,  4, 14), Color(0.18, 0.28, 0.55, a))
	draw_rect(Rect2(  5, -18,  4, 14), Color(0.18, 0.28, 0.55, a))

	# ── PIERNAS ──────────────────────────────────────────────
	draw_rect(Rect2(-21, -50, 17, 31), blue)
	draw_rect(Rect2( 4,  -50, 17, 31), blue)
	# línea de pantalón
	draw_line(Vector2(0, -50), Vector2(0, -20), dark, 1.5)

	# ── TORSO / ARMADURA ─────────────────────────────────────
	draw_rect(Rect2(-25, -90, 50, 41), navy)

	# ── RAYO EN EL PECHO ⚡ — con glow animado ───────────────
	# Halo de destello detrás del rayo
	draw_circle(Vector2(2, -68), 14.0 + pulse * 7.0,
		Color(1.0, 0.95, 0.1, pulse * 0.38 * a))

	var bolt := PackedVector2Array([
		Vector2( 5, -86),
		Vector2(-3, -70),
		Vector2( 2, -70),
		Vector2(-6, -53),
		Vector2( 8, -66),
		Vector2( 2, -66),
		Vector2( 9, -82),
		Vector2( 3, -82),
	])
	draw_colored_polygon(bolt, gold)

	# ── HOMBRERAS ────────────────────────────────────────────
	draw_rect(Rect2(-36, -90, 13, 11), gold)
	draw_rect(Rect2( 23, -90, 13, 11), gold)

	# ── BRAZOS ───────────────────────────────────────────────
	draw_rect(Rect2(-35, -86, 12, 36), blue)
	draw_rect(Rect2( 23, -86, 12, 36), blue)

	# ── GUANTES ──────────────────────────────────────────────
	draw_rect(Rect2(-35, -52, 12, 14), dark)
	draw_rect(Rect2( 23, -52, 12, 14), dark)

	# ── CUELLO ───────────────────────────────────────────────
	draw_rect(Rect2(-7, -98, 14, 9), skin)

	# ── CASCO ────────────────────────────────────────────────
	draw_circle(Vector2(0, -108), 21, navy)
	draw_rect(Rect2(-21, -116, 42, 22), navy)

	# ── VISERA DORADA ────────────────────────────────────────
	draw_rect(Rect2(-16, -113, 32, 11), gold)
	draw_rect(Rect2(-14, -112,  8,  7), shine)  # reflejo

	# ── FIN DEL CASCO (rayo arriba) ──────────────────────────
	var fin := PackedVector2Array([
		Vector2( 3, -120),
		Vector2(-5, -110),
		Vector2(-1, -110),
		Vector2(-7, -100),
		Vector2( 5, -108),
		Vector2( 1, -108),
		Vector2( 5, -118),
	])
	draw_colored_polygon(fin, gold)

# ─────────────────────────────────────────────────────────────
#  SOMBRA OVALADA EN EL SUELO
# ─────────────────────────────────────────────────────────────
func draw_ellipse_shadow() -> void:
	var cx  : float = 0.0
	var cy  : float = 6.0
	var rx  : float = DISPLAY_W * 0.38
	var ry  : float = 8.0
	var col : Color = Color(0, 0, 0, 0.18 if not completado else 0.08)
	var prev := Vector2(cx + rx, cy)
	for i in range(1, 33):
		var ang := TAU * float(i) / 32.0
		var cur  := Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry)
		draw_line(prev, cur, col, 1.0)
		prev = cur

# ─────────────────────────────────────────────────────────────
#  BADGE ✓ (completado)
# ─────────────────────────────────────────────────────────────
func _dibujar_check() -> void:
	var cx : float = DISPLAY_W * 0.5 - 4
	var cy : float = -DISPLAY_H + 4

	draw_circle(Vector2(cx + 1, cy + 1), 17.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_circle(Vector2(cx, cy),         17.0, Color(0.10, 0.72, 0.28))
	draw_arc(Vector2(cx, cy), 17.0, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 2.0)

	var c  := Color(1.0, 1.0, 1.0)
	var p1 := Vector2(cx - 8,  cy + 1)
	var p2 := Vector2(cx - 2,  cy + 7)
	var p3 := Vector2(cx + 9,  cy - 7)
	draw_line(p1, p2, c, 3.5)
	draw_line(p2, p3, c, 3.5)

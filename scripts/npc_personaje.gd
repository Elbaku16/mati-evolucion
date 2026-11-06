extends Node2D

# ═══════════════════════════════════════════════════════════════
#  NPC PERSONAJE — Usa la imagen real del NPC + badge ✓ cuando
#  el jugador ya completó su desafío.
# ═══════════════════════════════════════════════════════════════

const DISPLAY_W : float = 200.0   # Ancho de display en mundo 2D
const DISPLAY_H : float = 240.0   # Alto  de display en mundo 2D

var textura    : Texture2D = null
var completado : bool      = false

# ─────────────────────────────────────────────────────────────
func setup(tex: Texture2D) -> void:
	textura = tex
	queue_redraw()

func marcar_completado(val: bool) -> void:
	completado = val
	queue_redraw()

# ─────────────────────────────────────────────────────────────
#  DIBUJO PRINCIPAL
# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var alpha : float = 0.40 if completado else 1.0

	# Sombra en el suelo
	draw_ellipse_shadow()

	# Imagen del NPC centrada en el nodo
	if textura:
		var rect = Rect2(
			Vector2(-DISPLAY_W * 0.5, -DISPLAY_H),
			Vector2(DISPLAY_W, DISPLAY_H)
		)
		draw_texture_rect(textura, rect, false, Color(1, 1, 1, alpha))

	# Badge ✓ verde en esquina superior derecha cuando está completado
	if completado:
		_dibujar_check()

# ─────────────────────────────────────────────────────────────
#  SOMBRA OVALADA EN EL SUELO
# ─────────────────────────────────────────────────────────────
func draw_ellipse_shadow() -> void:
	# Dibuja una elipse usando líneas (Godot 4 no tiene draw_ellipse)
	var cx  : float = 0.0
	var cy  : float = 6.0
	var rx  : float = DISPLAY_W * 0.38
	var ry  : float = 8.0
	var col : Color = Color(0, 0, 0, 0.18 if not completado else 0.08)
	var prev = Vector2(cx + rx, cy)
	for i in range(1, 33):
		var ang  = TAU * float(i) / 32.0
		var cur  = Vector2(cx + cos(ang) * rx, cy + sin(ang) * ry)
		draw_line(prev, cur, col, 1.0)
		prev = cur

# ─────────────────────────────────────────────────────────────
#  BADGE ✓ (completado)
# ─────────────────────────────────────────────────────────────
func _dibujar_check() -> void:
	# Posición: esquina superior derecha de la imagen
	var cx : float = DISPLAY_W * 0.5 - 4
	var cy : float = -DISPLAY_H + 4

	# Círculo de fondo verde oscuro (sombra)
	draw_circle(Vector2(cx + 1, cy + 1), 17.0, Color(0.0, 0.0, 0.0, 0.35))
	# Círculo principal verde
	draw_circle(Vector2(cx, cy), 17.0, Color(0.10, 0.72, 0.28))
	# Borde blanco fino
	draw_arc(Vector2(cx, cy), 17.0, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 2.0)

	# Palomita ✓
	var c = Color(1.0, 1.0, 1.0)
	var p1 = Vector2(cx - 8,  cy + 1)
	var p2 = Vector2(cx - 2,  cy + 7)
	var p3 = Vector2(cx + 9,  cy - 7)
	draw_line(p1, p2, c, 3.5)
	draw_line(p2, p3, c, 3.5)

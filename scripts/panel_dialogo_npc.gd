extends Control

# ═══════════════════════════════════════════════════════════════
#  PANEL DIÁLOGO NPC — fondo naranja-amarillo con tab lateral
#  tab_derecha = true  → la pestañita aparece a la DERECHA
#  tab_derecha = false → la pestañita aparece a la IZQUIERDA
# ═══════════════════════════════════════════════════════════════

var tab_derecha : bool = false

const COL_NARANJA : Color = Color(0.98, 0.35, 0.12, 1.0)
const COL_AMARILLO: Color = Color(1.00, 0.87, 0.25, 1.0)
const COL_BORDE   : Color = Color(0.92, 0.25, 0.05, 1.0)
const COL_BRILLO  : Color = Color(1.00, 1.00, 1.00, 0.55)

const TAB_W  : float = 118.0
const TAB_H  : float = 38.0
const RADIO  : int   = 18

# ─────────────────────────────────────────────────────────────
func setup(es_derecha: bool) -> void:
	tab_derecha = es_derecha
	queue_redraw()

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0 or h <= 0:
		return

	# ── 1. Tab superior ──────────────────────────────────────
	var tx : float = (w - TAB_W - 20.0) if tab_derecha else 20.0
	_dibujar_caja(tx, -TAB_H + 6, TAB_W, TAB_H, 14, true)

	# ── 2. Cuerpo principal ──────────────────────────────────
	_dibujar_caja(0.0, 0.0, w, h, RADIO, false)

	# ── 3. Brillo (puntito blanco decorativo) ────────────────
	var bx : float = (w - 22.0) if tab_derecha else (w - 22.0)
	draw_circle(Vector2(bx, 8.0), 4.0, COL_BRILLO)
	draw_circle(Vector2(bx + 10.0, 8.0), 2.5, Color(1, 1, 1, 0.30))

# ─────────────────────────────────────────────────────────────
#  Dibuja una caja con gradiente naranja→amarillo + borde
# ─────────────────────────────────────────────────────────────
func _dibujar_caja(x: float, y: float, w: float, h: float,
				   r: int, es_tab: bool) -> void:
	const BANDAS : int = 30

	# Gradient usando polígonos horizontales
	for i in range(BANDAS):
		var t0 := float(i)        / float(BANDAS)
		var t1 := float(i + 1)   / float(BANDAS)
		var y0  := y + t0 * h
		var y1  := y + t1 * h
		var c0  := COL_NARANJA.lerp(COL_AMARILLO, t0)
		var c1  := COL_NARANJA.lerp(COL_AMARILLO, t1)
		draw_polygon(
			[Vector2(x, y0), Vector2(x + w, y0),
			 Vector2(x + w, y1), Vector2(x, y1)],
			[c0, c0, c1, c1]
		)

	# Borde naranja usando draw_rect con expand para esquinas
	# (simularemos con líneas de borde)
	_dibujar_borde(x, y, w, h, float(r), es_tab)

# ─────────────────────────────────────────────────────────────
#  Borde: arcos en esquinas + líneas en lados
# ─────────────────────────────────────────────────────────────
func _dibujar_borde(x: float, y: float, w: float, h: float,
					r: float, es_tab: bool) -> void:
	const GROSOR : float = 4.0
	var pts : PackedVector2Array = PackedVector2Array()

	# Esquina top-left
	for i in range(9):
		var a := PI + (PI * 0.5 * float(i) / 8.0)
		pts.append(Vector2(x + r + cos(a) * r, y + r + sin(a) * r))

	# Esquina top-right
	for i in range(9):
		var a := -PI * 0.5 + (PI * 0.5 * float(i) / 8.0)
		pts.append(Vector2(x + w - r + cos(a) * r, y + r + sin(a) * r))

	# Esquina bottom-right
	for i in range(9):
		var a := 0.0 + (PI * 0.5 * float(i) / 8.0)
		pts.append(Vector2(x + w - r + cos(a) * r, y + h - r + sin(a) * r))

	# Esquina bottom-left
	for i in range(9):
		var a := PI * 0.5 + (PI * 0.5 * float(i) / 8.0)
		pts.append(Vector2(x + r + cos(a) * r, y + h - r + sin(a) * r))

	# Cerrar
	pts.append(pts[0])
	draw_polyline(pts, COL_BORDE, GROSOR, true)

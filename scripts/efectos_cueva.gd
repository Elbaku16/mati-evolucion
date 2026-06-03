extends Node2D

# ═══════════════════════════════════════════════════════════════
#  EFECTOS CUEVA — Estalactitas y piedras que cuelgan del techo
#  Solo aparecen en la zona oscura (x > 4200).
#  Dibujado procedural: triángulos colgantes + gotita brillante.
# ═══════════════════════════════════════════════════════════════

const CUEVA_X_INI : float = 4200.0
const CUEVA_X_FIN : float = 6550.0
const TECHO_Y     : float =  150.0   # misma que LIMITE_ARR

var estalactitas : Array = []

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	z_index = -1   # detrás de NPCs y Mati, delante del fondo
	randomize()
	_generar()

# ─────────────────────────────────────────────────────────────
func _generar() -> void:
	var x := CUEVA_X_INI + 60.0
	while x < CUEVA_X_FIN - 60.0:
		var largo  : float = randf_range(35.0, 160.0)
		var ancho  : float = largo * randf_range(0.20, 0.42)
		var oscuro : float = randf_range(0.10, 0.22)   # luminancia
		estalactitas.append({
			"x"     : x,
			"largo" : largo,
			"ancho" : ancho,
			"col"   : Color(oscuro * 0.85, oscuro * 0.70, oscuro * 1.30, 0.88),
		})
		x += randf_range(55.0, 180.0)

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	for e in estalactitas:
		var ex : float = float(e["x"])
		var el : float = float(e["largo"])
		var ea : float = float(e["ancho"])
		var ec : Color = e["col"]

		# ── Cuerpo: trapecio (base ancha arriba, punta abajo) ──
		var pts := PackedVector2Array([
			Vector2(ex - ea,          TECHO_Y),
			Vector2(ex + ea,          TECHO_Y),
			Vector2(ex + ea * 0.18,   TECHO_Y + el),
			Vector2(ex - ea * 0.18,   TECHO_Y + el),
		])
		draw_colored_polygon(pts, ec)

		# ── Borde lateral más oscuro ──────────────────────────
		var borde := Color(ec.r * 0.55, ec.g * 0.55, ec.b * 0.60, 0.70)
		draw_line(Vector2(ex - ea, TECHO_Y),
		          Vector2(ex - ea * 0.18, TECHO_Y + el), borde, 1.5)
		draw_line(Vector2(ex + ea, TECHO_Y),
		          Vector2(ex + ea * 0.18, TECHO_Y + el), borde, 1.5)

		# ── Gotita brillante en la punta ─────────────────────
		draw_circle(
			Vector2(ex, TECHO_Y + el),
			ea * 0.28,
			Color(0.55, 0.62, 0.95, 0.50)
		)

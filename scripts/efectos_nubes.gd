extends Node2D

# ═══════════════════════════════════════════════════════════════
#  NUBES ANIMADAS — Flotan lentamente por el cielo del mundo.
#  Dibujo procedural: varias capas de círculos superpuestos.
# ═══════════════════════════════════════════════════════════════

const N_NUBES   : int   = 20
const MUNDO_IZQ : float = -5000.0
const MUNDO_DER : float =  7500.0
const CIELO_ARR : float =  110.0    # Y mínima — bien arriba en el cielo
const CIELO_ABA : float =  240.0    # Y máxima — por encima del nivel del suelo

var nubes  : Array = []
var tiempo : float = 0.0

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	z_index = -1   # detrás de NPCs y Mati, delante del fondo
	randomize()
	for _i in range(N_NUBES):
		_spawn(true)

# ─────────────────────────────────────────────────────────────
func _spawn(inicial: bool) -> void:
	var r   : float = randf_range(55.0, 115.0)
	var px  : float = MUNDO_DER + r + 40.0 if not inicial \
	                  else randf_range(MUNDO_IZQ, MUNDO_DER)
	var py  : float = randf_range(CIELO_ARR + r * 0.5, CIELO_ABA)

	nubes.append({
		"x"      : px,
		"y"      : py,
		"base_y" : py,
		"r"      : r,
		"vel"    : randf_range(8.0, 22.0),     # muy suaves
		"alpha"  : randf_range(0.58, 0.82),
		"bob_ph" : randf_range(0.0, TAU),
		"bob_f"  : randf_range(0.18, 0.45),
		"bob_a"  : randf_range(5.0, 14.0),
	})

# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	tiempo += delta
	var j : int = nubes.size() - 1
	while j >= 0:
		var n = nubes[j]
		n["x"] -= n["vel"] * delta
		n["y"]  = n["base_y"] + sin(tiempo * float(n["bob_f"]) + float(n["bob_ph"])) * float(n["bob_a"])
		if n["x"] < MUNDO_IZQ - float(n["r"]) - 60.0:
			nubes.remove_at(j)
			_spawn(false)
		j -= 1
	queue_redraw()

# ─────────────────────────────────────────────────────────────
func _draw() -> void:
	for n in nubes:
		_draw_nube(float(n["x"]), float(n["y"]), float(n["r"]), float(n["alpha"]))

# ─────────────────────────────────────────────────────────────
#  DIBUJO DE UNA NUBE
#  Tres capas de círculos: sombra → cuerpo → pompones brillantes
# ─────────────────────────────────────────────────────────────
func _draw_nube(cx: float, cy: float, r: float, a: float) -> void:
	# ── Capa 1: sombra inferior (gris-azulado) ─────────────────
	var cs := Color(0.74, 0.80, 0.92, a * 0.88)
	draw_circle(Vector2(cx - r * 0.58, cy + r * 0.28), r * 0.70, cs)
	draw_circle(Vector2(cx,             cy + r * 0.34), r * 0.78, cs)
	draw_circle(Vector2(cx + r * 0.58, cy + r * 0.28), r * 0.70, cs)

	# ── Capa 2: cuerpo principal (blanco suave) ─────────────────
	var cc := Color(0.95, 0.97, 1.00, a)
	draw_circle(Vector2(cx - r * 0.62, cy + r * 0.10), r * 0.76, cc)
	draw_circle(Vector2(cx,             cy            ), r * 0.88, cc)
	draw_circle(Vector2(cx + r * 0.62, cy + r * 0.10), r * 0.76, cc)

	# ── Capa 3: pompones superiores (blanco puro) ───────────────
	var ct := Color(1.0, 1.0, 1.0, a)
	draw_circle(Vector2(cx - r * 0.80, cy + r * 0.02), r * 0.53, ct)
	draw_circle(Vector2(cx - r * 0.42, cy - r * 0.30), r * 0.64, ct)
	draw_circle(Vector2(cx,             cy - r * 0.40), r * 0.70, ct)
	draw_circle(Vector2(cx + r * 0.42, cy - r * 0.30), r * 0.64, ct)
	draw_circle(Vector2(cx + r * 0.80, cy + r * 0.02), r * 0.53, ct)

	# ── Brillo en la cima (reflejo de sol) ──────────────────────
	draw_circle(
		Vector2(cx - r * 0.12, cy - r * 0.48),
		r * 0.38,
		Color(1.0, 1.0, 1.0, a * 0.50)
	)

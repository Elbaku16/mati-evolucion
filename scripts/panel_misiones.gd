extends Control

# ═══════════════════════════════════════════════════════════════
#  PANEL DE MISIONES Y COLECCIONABLES
#  Accesible desde el Mapa. Muestra todas las misiones con
#  nombre, estado, progreso y recompensa.
# ═══════════════════════════════════════════════════════════════

var _guardado = null
var _datos    : Dictionary = {}

const COLORES_PLANETA := {
	0: Color(0.6, 0.6, 1.0),
	1: Color(0.3, 1.0, 0.4),
	2: Color(0.4, 0.85, 1.0),
	3: Color(0.85, 0.3, 1.0),
}
const NOMBRES_PLANETA := {
	0: "Global",
	1: "🌿 Planeta Verde",
	2: "🧊 Planeta Hielo",
	3: "🍄 Planeta Hongos",
}

func _ready() -> void:
	_guardado = load("res://scripts/guardado.gd").new()
	_datos    = _guardado.cargar()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir_ui()

func _construir_ui() -> void:
	# Fondo oscuro
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.14, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Título
	var lbl_t := Label.new()
	lbl_t.text = "📋  Misiones y Coleccionables"
	lbl_t.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_t.offset_top = 14; lbl_t.offset_bottom = 54
	lbl_t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_t.add_theme_font_size_override("font_size", 28)
	lbl_t.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	add_child(lbl_t)

	# Resumen de coleccionables
	var total_col : int = int(_datos.get("coleccionables_total", 0))
	var lbl_col := Label.new()
	lbl_col.text = "Coleccionables: %d  |  Estrellas: %d  |  Monedas: %d" % [
		total_col,
		int(_datos.get("estrellas", 0)),
		int(_datos.get("monedas", 0))
	]
	lbl_col.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_col.offset_top = 56; lbl_col.offset_bottom = 86
	lbl_col.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_col.add_theme_font_size_override("font_size", 18)
	lbl_col.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	add_child(lbl_col)

	# Contenedor scrollable
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 90)
	scroll.size     = Vector2(1240, 580)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size   = Vector2(1200, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	# Agrupar misiones por planeta
	var por_planeta : Dictionary = {}
	for m in load("res://scripts/misiones.gd").MISIONES:
		var p : int = int(m.get("planeta", 0))
		if not por_planeta.has(p):
			por_planeta[p] = []
		por_planeta[p].append(m)

	var orden_planetas := [1, 2, 3, 0]
	for p in orden_planetas:
		if not por_planeta.has(p):
			continue

		# Encabezado de planeta
		var lbl_p := Label.new()
		lbl_p.text = NOMBRES_PLANETA.get(p, "Planeta %d" % p)
		lbl_p.add_theme_font_size_override("font_size", 22)
		lbl_p.add_theme_color_override("font_color",
			COLORES_PLANETA.get(p, Color.WHITE))
		lbl_p.custom_minimum_size = Vector2(1200, 36)
		vbox.add_child(lbl_p)

		# Separador
		var sep := HSeparator.new()
		sep.custom_minimum_size = Vector2(1200, 2)
		vbox.add_child(sep)

		for m in por_planeta[p]:
			vbox.add_child(_crear_fila_mision(m))

		# Espacio entre grupos
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		vbox.add_child(spacer)

	# Botón volver
	var btn_v := Button.new()
	btn_v.text = "← Volver"
	btn_v.position = Vector2(16, 668)
	btn_v.size     = Vector2(140, 44)
	btn_v.add_theme_font_size_override("font_size", 20)
	btn_v.pressed.connect(func():
		TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")
	)
	add_child(btn_v)

func _crear_fila_mision(m: Dictionary) -> Control:
	var id    : String = m["id"]
	var completa : bool = load("res://scripts/misiones.gd").esta_completa(id, _datos)
	var prog  : int    = load("res://scripts/misiones.gd").get_progreso(id, _datos)
	var obj   : int    = int(m.get("objetivo", 1))

	var fila := Panel.new()
	fila.custom_minimum_size = Vector2(1200, 72)
	var sty := StyleBoxFlat.new()
	var col_borde := COLORES_PLANETA.get(int(m.get("planeta", 0)), Color(0.5, 0.5, 0.8))
	sty.bg_color = Color(0.08, 0.06, 0.18, 0.9) if not completa else Color(0.05, 0.14, 0.05, 0.9)
	sty.border_width_left   = 3
	sty.border_color = col_borde if completa else Color(col_borde.r, col_borde.g, col_borde.b, 0.4)
	sty.corner_radius_top_left    = 8; sty.corner_radius_top_right    = 8
	sty.corner_radius_bottom_left = 8; sty.corner_radius_bottom_right = 8
	fila.add_theme_stylebox_override("panel", sty)

	# Icono
	var lbl_ico := Label.new()
	lbl_ico.text     = str(m.get("icono", "⭐"))
	lbl_ico.position = Vector2(10, 18)
	lbl_ico.size     = Vector2(40, 36)
	lbl_ico.add_theme_font_size_override("font_size", 28)
	fila.add_child(lbl_ico)

	# Nombre
	var lbl_nom := Label.new()
	lbl_nom.text = m["nombre"]
	lbl_nom.position = Vector2(56, 6)
	lbl_nom.size     = Vector2(320, 30)
	lbl_nom.add_theme_font_size_override("font_size", 18)
	lbl_nom.add_theme_color_override("font_color",
		Color(0.5, 1.0, 0.5) if completa else Color(0.9, 0.9, 1.0))
	fila.add_child(lbl_nom)

	# Descripción
	var lbl_desc := Label.new()
	lbl_desc.text = m.get("descripcion", "")
	lbl_desc.position = Vector2(56, 36)
	lbl_desc.size     = Vector2(560, 28)
	lbl_desc.add_theme_font_size_override("font_size", 14)
	lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.65, 0.8))
	fila.add_child(lbl_desc)

	# Estado
	var estado_txt : String
	var estado_col : Color
	if completa:
		estado_txt = "✓ Completada"
		estado_col = Color(0.4, 1.0, 0.4)
	else:
		estado_txt = "En progreso"
		estado_col = Color(0.9, 0.85, 0.3)
	var lbl_est := Label.new()
	lbl_est.text = estado_txt
	lbl_est.position = Vector2(640, 6)
	lbl_est.size     = Vector2(180, 30)
	lbl_est.add_theme_font_size_override("font_size", 16)
	lbl_est.add_theme_color_override("font_color", estado_col)
	fila.add_child(lbl_est)

	# Recompensa
	var tipo_r := str(m.get("recompensa_tipo", "monedas"))
	var val_r  := int(m.get("recompensa", 0))
	var ico_r  := "🪙" if tipo_r == "monedas" else "⭐"
	var lbl_rew := Label.new()
	lbl_rew.text = "%s +%d" % [ico_r, val_r]
	lbl_rew.position = Vector2(640, 36)
	lbl_rew.size     = Vector2(180, 28)
	lbl_rew.add_theme_font_size_override("font_size", 15)
	lbl_rew.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	fila.add_child(lbl_rew)

	# Barra de progreso
	var prog_real := min(prog, obj)
	var pct : float = float(prog_real) / float(obj) if obj > 0 else 1.0

	var bg_bar := ColorRect.new()
	bg_bar.color    = Color(0.15, 0.15, 0.25)
	bg_bar.position = Vector2(840, 24)
	bg_bar.size     = Vector2(280, 20)
	fila.add_child(bg_bar)

	var fill := ColorRect.new()
	fill.color    = Color(0.3, 0.9, 0.4) if completa else Color(0.3, 0.6, 0.9)
	fill.position = Vector2(840, 24)
	fill.size     = Vector2(280.0 * pct, 20)
	fila.add_child(fill)

	var lbl_prog := Label.new()
	lbl_prog.text = "%d / %d" % [prog_real, obj]
	lbl_prog.position = Vector2(840, 24)
	lbl_prog.size     = Vector2(280, 20)
	lbl_prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_prog.add_theme_font_size_override("font_size", 13)
	lbl_prog.add_theme_color_override("font_color", Color.WHITE)
	fila.add_child(lbl_prog)

	return fila

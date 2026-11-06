extends Control

# ═══════════════════════════════════════════════════════════════
#  MINIJUEGO CONSTRUCCIÓN — Reparar nave espacial
#
#  El jugador resuelve 4 retos matemáticos para recuperar las
#  piezas de una nave averiada. Al terminar, la nave despega
#  con una animación de reconstrucción.
#
#  Config (user://construccion_config.json):
#    {
#      "titulo":       "Nave Averiada",
#      "nivel":        1,          # 1-3 controla dificultad de operaciones
#      "monedas":      12,
#      "seccion_id":   300,
#      "escena_origen":"res://scenes/Mapa.tscn"
#    }
#
#  Llamada:
#    MinijuegoConstruccion.guardar_config({...})
#    TransitionManager.cambiar_escena("res://scenes/MinijuegoConstruccion.tscn")
# ═══════════════════════════════════════════════════════════════

static func guardar_config(cfg: Dictionary) -> void:
	const TEMP := "user://construccion_config.json"
	var f := FileAccess.open(TEMP, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))
		f.close()

func _leer_config() -> Dictionary:
	var defaults := {
		"titulo":        "Nave Averiada",
		"nivel":         1,
		"monedas":       12,
		"seccion_id":    0,
		"escena_origen": "res://scenes/Mapa.tscn"
	}
	const TEMP := "user://construccion_config.json"
	if FileAccess.file_exists(TEMP):
		var f := FileAccess.open(TEMP, FileAccess.READ)
		if f:
			var j := JSON.new()
			if j.parse(f.get_as_text()) == OK:
				for k in j.data:
					defaults[k] = j.data[k]
			f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP))
	return defaults

# ─────────────────────────────────────────────────────────────
#  DATOS DE PIEZAS
# ─────────────────────────────────────────────────────────────
const PIEZAS := [
	{"id": 0, "nombre": "Motor",         "icono": "⚙️",  "color": Color(0.9,  0.5,  0.1)},
	{"id": 1, "nombre": "Ala Izquierda", "icono": "◀",   "color": Color(0.2,  0.6,  1.0)},
	{"id": 2, "nombre": "Ala Derecha",   "icono": "▶",   "color": Color(0.2,  0.6,  1.0)},
	{"id": 3, "nombre": "Núcleo",        "icono": "⚡",  "color": Color(0.3,  1.0,  0.5)},
]

# ─────────────────────────────────────────────────────────────
#  ESTADO
# ─────────────────────────────────────────────────────────────
var _config     : Dictionary = {}
var _guardado                 = null
var _efectos                  = null
var _nivel      : int         = 1

var _piezas_ok  : Array = [false, false, false, false]
var _etapa      : String = "juego"   # juego | reto | victoria

# UI
var _nave_node  : Node2D = null
var _slots      : Array  = []   # 4 nodos _Slot
var _lbl_titulo : Label  = null
var _lbl_prog   : Label  = null
var _panel_reto : Control = null   # panel flotante para el reto activo
var _reto_idx   : int     = -1

# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	_guardado = load("res://scripts/guardado.gd").new()
	_efectos  = load("res://scripts/efectos_ui.gd")
	_config   = _leer_config()
	_nivel    = int(_config.get("nivel", 1))

	set_anchors_preset(Control.PRESET_FULL_RECT)
	_construir_ui()

# ─────────────────────────────────────────────────────────────
#  CONSTRUCCIÓN UI
# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	# Fondo espacial oscuro
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Estrellas de fondo
	var estrellas := _Estrellas.new()
	estrellas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(estrellas)

	# Título
	_lbl_titulo = Label.new()
	_lbl_titulo.text = _config.get("titulo", "Nave Averiada")
	_lbl_titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_lbl_titulo.offset_top  = 12.0
	_lbl_titulo.offset_bottom = 50.0
	_lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_titulo.add_theme_font_size_override("font_size", 30)
	_lbl_titulo.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	add_child(_lbl_titulo)

	# Progreso
	_lbl_prog = Label.new()
	_lbl_prog.text = "Piezas: 0 / 4"
	_lbl_prog.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_lbl_prog.offset_top    = 52.0
	_lbl_prog.offset_bottom = 82.0
	_lbl_prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_prog.add_theme_font_size_override("font_size", 20)
	_lbl_prog.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
	add_child(_lbl_prog)

	# Nave dibujada (centro)
	_nave_node = _Nave.new()
	_nave_node.position = Vector2(640, 390)
	_nave_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nave_node)

	# 4 slots de piezas alrededor de la nave
	var slot_posiciones := [
		Vector2(640, 160),   # Motor (arriba)
		Vector2(290, 420),   # Ala izquierda
		Vector2(990, 420),   # Ala derecha
		Vector2(640, 620),   # Núcleo (abajo)
	]
	for i in 4:
		var slot := _Slot.new()
		slot.idx         = i
		slot.pieza_data  = PIEZAS[i]
		slot.completado  = false
		slot.position    = slot_posiciones[i]
		slot.size        = Vector2(140, 110)
		slot.pivot_offset = Vector2(70, 55)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(func(ev): _on_slot_input(i, ev))
		add_child(slot)
		_slots.append(slot)

	# Panel de reto (inicialmente oculto)
	_panel_reto = Control.new()
	_panel_reto.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_reto.visible = false
	add_child(_panel_reto)

	# Botón volver
	var btn_v := Button.new()
	btn_v.text = "← Salir"
	btn_v.position = Vector2(16, 668)
	btn_v.size     = Vector2(130, 42)
	btn_v.add_theme_font_size_override("font_size", 18)
	btn_v.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)
	add_child(btn_v)

# ─────────────────────────────────────────────────────────────
#  INTERACCIÓN CON SLOTS
# ─────────────────────────────────────────────────────────────
func _on_slot_input(idx: int, event: InputEvent) -> void:
	if _etapa != "juego":
		return
	if _piezas_ok[idx]:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_abrir_reto(idx)

# ─────────────────────────────────────────────────────────────
#  RETO MATEMÁTICO
# ─────────────────────────────────────────────────────────────
func _generar_reto(idx: int) -> Dictionary:
	# Dificultad escalada por nivel y por índice de pieza
	var dif : int = _nivel + idx / 2
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	match idx:
		0:  # Motor — suma/resta
			var a : int = rng.randi_range(5 * dif, 15 * dif)
			var b : int = rng.randi_range(2 * dif, 10 * dif)
			if randi() % 2 == 0:
				return {"pregunta": "%d + %d = ?" % [a, b], "respuesta": a + b, "tipo": "numero"}
			else:
				return {"pregunta": "%d − %d = ?" % [a + b, b], "respuesta": a, "tipo": "numero"}
		1:  # Ala izquierda — multiplicación
			var a2 : int = rng.randi_range(2, 4 + dif)
			var b2 : int = rng.randi_range(2, 5 + dif)
			return {"pregunta": "%d × %d = ?" % [a2, b2], "respuesta": a2 * b2, "tipo": "numero"}
		2:  # Ala derecha — número faltante
			var a3 : int = rng.randi_range(2, 4 + dif)
			var b3 : int = rng.randi_range(3, 6 + dif)
			return {"pregunta": "__ × %d = %d" % [b3, a3 * b3], "respuesta": a3, "tipo": "numero"}
		3:  # Núcleo — secuencia
			var ini : int = rng.randi_range(1, 5 * dif)
			var paso : int = rng.randi_range(2, 3 + dif)
			return {
				"pregunta": "%d, %d, %d, __ =" % [ini, ini + paso, ini + paso * 2],
				"respuesta": ini + paso * 3,
				"tipo": "numero"
			}
	return {"pregunta": "1 + 1 = ?", "respuesta": 2, "tipo": "numero"}

func _abrir_reto(idx: int) -> void:
	_reto_idx = idx
	_etapa    = "reto"
	var reto  := _generar_reto(idx)
	var pieza := PIEZAS[idx]

	# Limpiar panel
	for child in _panel_reto.get_children():
		child.queue_free()
	_panel_reto.visible = true

	# Fondo semitransparente
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_reto.add_child(overlay)

	# Tarjeta del reto
	var card := Panel.new()
	card.position = Vector2(340, 190)
	card.size     = Vector2(600, 320)
	var sty := StyleBoxFlat.new()
	sty.bg_color   = Color(0.06, 0.04, 0.18, 0.97)
	sty.border_width_left = 3; sty.border_width_right  = 3
	sty.border_width_top  = 3; sty.border_width_bottom = 3
	sty.border_color = pieza["color"]
	sty.corner_radius_top_left    = 18; sty.corner_radius_top_right    = 18
	sty.corner_radius_bottom_left = 18; sty.corner_radius_bottom_right = 18
	card.add_theme_stylebox_override("panel", sty)
	_panel_reto.add_child(card)

	# Icono + nombre
	var lbl_ico := Label.new()
	lbl_ico.text = pieza["icono"] + "  " + pieza["nombre"]
	lbl_ico.position = Vector2(0, 18)
	lbl_ico.size     = Vector2(600, 42)
	lbl_ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ico.add_theme_font_size_override("font_size", 26)
	lbl_ico.add_theme_color_override("font_color", pieza["color"])
	card.add_child(lbl_ico)

	# Pregunta
	var lbl_q := Label.new()
	lbl_q.text = reto["pregunta"]
	lbl_q.position = Vector2(0, 72)
	lbl_q.size     = Vector2(600, 50)
	lbl_q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_q.add_theme_font_size_override("font_size", 34)
	lbl_q.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(lbl_q)

	# Feedback
	var lbl_fb := Label.new()
	lbl_fb.name     = "Feedback"
	lbl_fb.position = Vector2(0, 128)
	lbl_fb.size     = Vector2(600, 32)
	lbl_fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_fb.add_theme_font_size_override("font_size", 20)
	lbl_fb.visible = false
	card.add_child(lbl_fb)

	# 4 opciones numéricas
	var correcto : int = int(reto["respuesta"])
	var opciones := _generar_opciones(correcto)
	var btn_x := [60.0, 240.0, 60.0, 240.0]
	var btn_y := [170.0, 170.0, 240.0, 240.0]
	for i in 4:
		var val := opciones[i]
		var btn := Button.new()
		btn.text     = str(val)
		btn.position = Vector2(btn_x[i], btn_y[i])
		btn.size     = Vector2(160, 56)
		btn.add_theme_font_size_override("font_size", 24)
		card.add_child(btn)
		btn.pressed.connect(func():
			_evaluar_reto(val, correcto, card, lbl_fb)
		)

	# Botón cerrar
	var btn_c := Button.new()
	btn_c.text     = "✕"
	btn_c.position = Vector2(555, 8)
	btn_c.size     = Vector2(36, 36)
	btn_c.add_theme_font_size_override("font_size", 18)
	card.add_child(btn_c)
	btn_c.pressed.connect(func():
		_panel_reto.visible = false
		_etapa = "juego"
	)

func _generar_opciones(correcto: int) -> Array:
	var ops : Array = [correcto]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	while ops.size() < 4:
		var delta := rng.randi_range(1, max(3, correcto / 3 + 1))
		var v : int = correcto + (delta if randi() % 2 == 0 else -delta)
		if v > 0 and not v in ops:
			ops.append(v)
	ops.shuffle()
	return ops

func _evaluar_reto(elegida: int, correcta: int, card: Control, lbl_fb: Label) -> void:
	if elegida == correcta:
		if _efectos:
			_efectos.flash_correcto(get_tree().root)
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx("correcto")
		lbl_fb.text = "✓ ¡Correcto!"
		lbl_fb.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		lbl_fb.visible = true
		# Desactivar botones
		for btn in card.get_children():
			if btn is Button and btn.text != "✕":
				btn.disabled = true
		await get_tree().create_timer(0.8).timeout
		_panel_reto.visible = false
		_etapa = "juego"
		_colocar_pieza(_reto_idx)
	else:
		if _efectos:
			_efectos.flash_incorrecto(get_tree().root)
		if Engine.has_singleton("MusicaManager"):
			Engine.get_singleton("MusicaManager").play_sfx("incorrecto")
		lbl_fb.text = "✗  Inténtalo de nuevo"
		lbl_fb.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		lbl_fb.visible = true

# ─────────────────────────────────────────────────────────────
#  COLOCAR PIEZA — ANIMACIÓN
# ─────────────────────────────────────────────────────────────
func _colocar_pieza(idx: int) -> void:
	_piezas_ok[idx] = true
	var slot : Control = _slots[idx]
	slot.completado = true
	slot.queue_redraw()

	# Animación pop del slot
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(slot, "scale", Vector2(1.4, 1.4), 0.12)
	tw.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.20)

	# Partículas en la nave
	if _efectos:
		_efectos.estrella_burst(get_tree().root,
			_nave_node.global_position + _offset_pieza(idx), 5)

	# Actualizar nave
	if _nave_node and _nave_node.has_method("set_pieza_ok"):
		_nave_node.call("set_pieza_ok", idx, true)

	var n_ok : int = _piezas_ok.count(true)
	_lbl_prog.text = "Piezas: %d / 4" % n_ok

	if n_ok == 4:
		await get_tree().create_timer(0.5).timeout
		_victoria()

func _offset_pieza(idx: int) -> Vector2:
	match idx:
		0: return Vector2(0, -130)
		1: return Vector2(-160, 0)
		2: return Vector2(160, 0)
		3: return Vector2(0, 100)
	return Vector2.ZERO

# ─────────────────────────────────────────────────────────────
#  VICTORIA
# ─────────────────────────────────────────────────────────────
func _victoria() -> void:
	_etapa = "victoria"
	var monedas : int = int(_config.get("monedas", 12))
	var sec_id  : int = int(_config.get("seccion_id", 0))

	var datos := _guardado.cargar()
	if sec_id > 0:
		var secs : Array = datos.get("secciones", [])
		if not sec_id in secs:
			secs.append(sec_id)
		datos["secciones"] = secs
	datos["monedas"]   = int(datos.get("monedas",   0)) + monedas
	datos["estrellas"] = int(datos.get("estrellas", 0)) + 2
	var arch := FileAccess.open(_guardado._ruta(), FileAccess.WRITE)
	if arch:
		arch.store_string(JSON.stringify(datos))
		arch.close()

	# Animación nave despegando
	if _nave_node:
		if _nave_node.has_method("animar_despegue"):
			_nave_node.call("animar_despegue")
		else:
			var tw2 := create_tween()
			tw2.set_ease(Tween.EASE_IN)
			tw2.tween_property(_nave_node, "position:y", -300.0, 1.5)
			tw2.parallel().tween_property(_nave_node, "modulate:a", 0.0, 1.5)

	if _efectos:
		_efectos.flash_dorado(get_tree().root)
	var cel = load("res://scripts/celebracion.gd")
	if cel:
		cel.lanzar(get_tree().root)
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx("fanfare")

	await get_tree().create_timer(1.2).timeout

	# Panel de victoria
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)

	var ovl := ColorRect.new()
	ovl.color = Color(0.0, 0.03, 0.08, 0.90)
	ovl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ovl.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(ovl)

	var lbl := Label.new()
	lbl.text = "🚀 ¡Nave reparada!\n+%d 🪙   +⭐⭐" % monedas
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 1.0))
	ovl.add_child(lbl)

	var btn := Button.new()
	btn.text = "Continuar ▶"
	btn.size = Vector2(240, 60)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_CENTER)
	btn.offset_left = -120; btn.offset_top = -100
	btn.offset_right = 120; btn.offset_bottom = -40
	btn.add_theme_font_size_override("font_size", 26)
	ovl.add_child(btn)
	btn.pressed.connect(func():
		TransitionManager.cambiar_escena(_config.get("escena_origen", "res://scenes/Mapa.tscn"))
	)

# ─────────────────────────────────────────────────────────────
#  CLASES INTERNAS — DIBUJADO PROCEDURAL
# ─────────────────────────────────────────────────────────────

class _Estrellas extends Node2D:
	var _pts : Array = []
	func _ready() -> void:
		var rng := RandomNumberGenerator.new(); rng.randomize()
		for _i in 80:
			_pts.append({
				"x": rng.randf_range(0, 1280),
				"y": rng.randf_range(0, 720),
				"r": rng.randf_range(1.0, 2.5),
				"a": rng.randf_range(0.4, 1.0)
			})
	func _draw() -> void:
		for p in _pts:
			draw_circle(Vector2(p["x"], p["y"]), p["r"],
			            Color(1, 1, 1, p["a"]))

class _Nave extends Node2D:
	var piezas_ok : Array = [false, false, false, false]
	var _tiempo   : float = 0.0
	var _volando  : bool  = false

	func set_pieza_ok(idx: int, val: bool) -> void:
		piezas_ok[idx] = val
		queue_redraw()

	func animar_despegue() -> void:
		_volando = true

	func _process(delta: float) -> void:
		_tiempo += delta
		queue_redraw()

	func _draw() -> void:
		var t := _tiempo
		var bob := sin(t * 1.5) * 4.0 if not _volando else 0.0
		var base := Vector2(0, bob)

		# Cuerpo central
		var col_cuerpo := Color(0.4, 0.5, 0.7)
		draw_rect(Rect2(base + Vector2(-55, -50), Vector2(110, 100)),
		          col_cuerpo, true)
		draw_rect(Rect2(base + Vector2(-55, -50), Vector2(110, 100)),
		          Color(0.6, 0.7, 1.0, 0.8), false, 2.0)

		# Cúpula
		draw_arc(base + Vector2(0, -50), 42.0, PI, TAU, 32,
		         Color(0.6, 0.85, 1.0, 0.9), 3.0)
		draw_circle(base + Vector2(0, -50), 38.0,
		            Color(0.5, 0.75, 0.95, 0.4))

		# Ventana
		draw_circle(base + Vector2(0, -55), 16.0, Color(0.2, 0.6, 0.9, 0.9))
		draw_circle(base + Vector2(0, -55), 10.0, Color(0.5, 0.85, 1.0, 0.7))

		# Motor (arriba) — slot 0
		if piezas_ok[0]:
			var mc := Color(0.9, 0.5, 0.1)
			draw_rect(Rect2(base + Vector2(-25, -90), Vector2(50, 42)), mc, true)
			draw_rect(Rect2(base + Vector2(-25, -90), Vector2(50, 42)),
			          mc.lightened(0.4), false, 2.0)
			# Llama del motor
			var flame := Color(1.0, 0.6, 0.1,
			                   0.6 + 0.3 * sin(t * 8.0))
			draw_circle(base + Vector2(0, -105), 12.0 + sin(t * 10) * 2, flame)
		else:
			draw_rect(Rect2(base + Vector2(-25, -90), Vector2(50, 42)),
			          Color(0.3, 0.3, 0.4, 0.5), true)
			draw_arc(base + Vector2(0, -69), 14, 0, TAU, 16,
			         Color(0.5, 0.5, 0.6, 0.6), 1.5)

		# Ala izquierda — slot 1
		if piezas_ok[1]:
			var points_l := PackedVector2Array([
				base + Vector2(-55, -20),
				base + Vector2(-130, 10),
				base + Vector2(-130, 50),
				base + Vector2(-55, 40),
			])
			draw_colored_polygon(points_l, Color(0.2, 0.55, 0.95))
			draw_polyline(points_l, Color(0.5, 0.8, 1.0, 0.8), 2.0)
		else:
			var pts_l := PackedVector2Array([
				base + Vector2(-55, -20),
				base + Vector2(-100, 5),
				base + Vector2(-100, 40),
				base + Vector2(-55, 40),
			])
			draw_colored_polygon(pts_l, Color(0.2, 0.3, 0.5, 0.4))

		# Ala derecha — slot 2
		if piezas_ok[2]:
			var points_r := PackedVector2Array([
				base + Vector2(55, -20),
				base + Vector2(130, 10),
				base + Vector2(130, 50),
				base + Vector2(55, 40),
			])
			draw_colored_polygon(points_r, Color(0.2, 0.55, 0.95))
			draw_polyline(points_r, Color(0.5, 0.8, 1.0, 0.8), 2.0)
		else:
			var pts_r := PackedVector2Array([
				base + Vector2(55, -20),
				base + Vector2(100, 5),
				base + Vector2(100, 40),
				base + Vector2(55, 40),
			])
			draw_colored_polygon(pts_r, Color(0.2, 0.3, 0.5, 0.4))

		# Núcleo de energía — slot 3
		if piezas_ok[3]:
			var nc := Color(0.3, 1.0, 0.5,
			                0.8 + 0.15 * sin(t * 6.0))
			draw_circle(base + Vector2(0, 70), 20.0, nc)
			draw_arc(base + Vector2(0, 70), 26.0, 0, TAU, 32,
			         nc.lightened(0.3), 3.0)
		else:
			draw_circle(base + Vector2(0, 70), 20.0,
			            Color(0.3, 0.4, 0.3, 0.4))
			draw_arc(base + Vector2(0, 70), 26.0, 0, TAU, 16,
			         Color(0.4, 0.5, 0.4, 0.4), 1.5)

		# Tobera de escape
		draw_rect(Rect2(base + Vector2(-30, 50), Vector2(60, 20)),
		          Color(0.5, 0.5, 0.6), true)
		# Llama tobera (siempre animada)
		var fl := Color(1.0, 0.4, 0.1, 0.5 + 0.3 * sin(t * 9.0))
		draw_circle(base + Vector2(-15, 78 + sin(t * 11) * 3), 7.0, fl)
		draw_circle(base + Vector2( 15, 76 + sin(t * 13) * 3), 7.0, fl)

class _Slot extends Control:
	var idx         : int        = 0
	var pieza_data  : Dictionary = {}
	var completado  : bool       = false
	var _hover      : bool       = false
	var _tiempo     : float      = 0.0

	func _ready() -> void:
		mouse_entered.connect(func(): _hover = true;  queue_redraw())
		mouse_exited.connect( func(): _hover = false; queue_redraw())

	func _process(delta: float) -> void:
		_tiempo += delta
		if not completado:
			queue_redraw()

	func _draw() -> void:
		var w := size.x; var h := size.y
		var col : Color = pieza_data.get("color", Color.GRAY)

		if completado:
			# Fondo sólido completo con brillo
			var sty_col := col.lerp(Color.WHITE, 0.25)
			draw_rect(Rect2(2, 2, w - 4, h - 4), sty_col, true)
			draw_rect(Rect2(2, 2, w - 4, h - 4),
			          Color(1, 1, 1, 0.9), false, 3.0)
			# Icono
			var icono : String = pieza_data.get("icono", "✓")
			# No podemos draw_string fácilmente para emojis; usamos "✓"
			# (el icono emoji puede no renderizar en _draw; label sería mejor)
			draw_arc(Vector2(w * 0.5, h * 0.5), min(w, h) * 0.3, 0, TAU, 32,
			         Color(1, 1, 1, 0.5), 2.0)
		else:
			# Pulsante vacío
			var alpha := 0.3 + 0.2 * sin(_tiempo * 3.0)
			var hover_extra := 0.2 if _hover else 0.0
			draw_rect(Rect2(2, 2, w - 4, h - 4),
			          Color(col.r, col.g, col.b, alpha + hover_extra), true)
			draw_rect(Rect2(2, 2, w - 4, h - 4),
			          Color(col.r, col.g, col.b,
			                0.7 + hover_extra), false, 2.0)
			# Cruz de "faltante"
			var c := Vector2(w * 0.5, h * 0.5)
			var r := min(w, h) * 0.22
			draw_line(c - Vector2(r, 0), c + Vector2(r, 0),
			          Color(col.r, col.g, col.b, 0.6 + hover_extra), 2.5)
			draw_line(c - Vector2(0, r), c + Vector2(0, r),
			          Color(col.r, col.g, col.b, 0.6 + hover_extra), 2.5)
			# Nombre
			# (draw_string omite soporte emoji; sería mejor Label hijo; usamos círculo indicador)
			draw_arc(c, r * 1.6, 0, TAU * (0.4 + 0.1 * sin(_tiempo * 2.0)), 32,
			         Color(col.r, col.g, col.b, 0.35 + hover_extra), 1.5)

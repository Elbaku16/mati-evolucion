extends Control

# ═══════════════════════════════════════════════════════════════
#  MENÚ PRINCIPAL — Efectos visuales animados
# ═══════════════════════════════════════════════════════════════

var _overlay : ColorRect = null

func _ready() -> void:
	$Jugar.pressed.connect(_on_jugar_presionado)
	$BtnAjustes.pressed.connect(_on_ajustes_presionado)
	$PanelAjustes/BtnCerrar.pressed.connect(_on_cerrar_ajustes)
	$PanelAjustes/BtnVolumen.pressed.connect(_on_volumen_presionado)
	$PanelAjustes.visible = false

	if not $Musica.playing:
		$Musica.play()

	# Overlay negro para fade in/out
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1.0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Fade-in de entrada
	var tw_in := create_tween()
	tw_in.tween_property(_overlay, "color:a", 0.0, 0.7)

	# Efectos — todos leen su posición original ANTES de animar
	_animar_cohete()
	_animar_mati()
	_animar_planetas()
	_animar_titulo()
	_animar_boton_jugar()
	_crear_estrellas()
	_efecto_agua()

# ─────────────────────────────────────────────────────────────
#  🚀 COHETE — vuela derecha → vuelve → izquierda → vuelve
# ─────────────────────────────────────────────────────────────
func _animar_cohete() -> void:
	var ox : float = $Cohete.position.x   # posición original en X
	var oy : float = $Cohete.position.y   # posición original en Y
	var od : float = rad_to_deg($Cohete.rotation)  # ángulo original

	# Horizontal: derecha → centro → izquierda → centro → loop
	var tx := create_tween()
	tx.set_loops()
	tx.set_ease(Tween.EASE_IN_OUT)
	tx.set_trans(Tween.TRANS_SINE)
	tx.tween_property($Cohete, "position:x", ox + 32.0, 1.3)
	tx.tween_property($Cohete, "position:x", ox,        1.0)
	tx.tween_property($Cohete, "position:x", ox - 32.0, 1.3)
	tx.tween_property($Cohete, "position:x", ox,        1.0)

	# Deriva vertical leve (distinta fase)
	var ty := create_tween()
	ty.set_loops()
	ty.set_ease(Tween.EASE_IN_OUT)
	ty.set_trans(Tween.TRANS_SINE)
	ty.tween_property($Cohete, "position:y", oy + 9.0, 1.3).set_delay(0.6)
	ty.tween_property($Cohete, "position:y", oy,        1.0)
	ty.tween_property($Cohete, "position:y", oy - 9.0, 1.3)
	ty.tween_property($Cohete, "position:y", oy,        1.0)

	# Banqueo sincronizado: se inclina hacia donde va
	var tr := create_tween()
	tr.set_loops()
	tr.set_ease(Tween.EASE_IN_OUT)
	tr.set_trans(Tween.TRANS_SINE)
	tr.tween_property($Cohete, "rotation_degrees", od + 7.0, 1.3)
	tr.tween_property($Cohete, "rotation_degrees", od,        1.0)
	tr.tween_property($Cohete, "rotation_degrees", od - 7.0, 1.3)
	tr.tween_property($Cohete, "rotation_degrees", od,        1.0)

# ─────────────────────────────────────────────────────────────
#  🐛 MATI — sube → vuelve → baja → vuelve (pegado al título)
# ─────────────────────────────────────────────────────────────
func _animar_mati() -> void:
	var oy : float = $Mati.position.y   # posición original en Y
	var od : float = $Mati.rotation_degrees  # ángulo original (0)

	# Bob vertical: arriba → centro → abajo → centro → loop
	var tw := create_tween()
	tw.set_loops()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property($Mati, "position:y", oy - 6.0, 0.8).set_delay(0.3)
	tw.tween_property($Mati, "position:y", oy,        0.7)
	tw.tween_property($Mati, "position:y", oy + 6.0, 0.8)
	tw.tween_property($Mati, "position:y", oy,        0.7)

	# Rotación: izquierda → centro → derecha → centro → loop
	var tr := create_tween()
	tr.set_loops()
	tr.set_ease(Tween.EASE_IN_OUT)
	tr.set_trans(Tween.TRANS_SINE)
	tr.tween_property($Mati, "rotation_degrees", od - 3.0, 0.8).set_delay(0.3)
	tr.tween_property($Mati, "rotation_degrees", od,        0.7)
	tr.tween_property($Mati, "rotation_degrees", od + 3.0, 0.8)
	tr.tween_property($Mati, "rotation_degrees", od,        0.7)

# ─────────────────────────────────────────────────────────────
#  🪨 PLANETAS — bobbing relativo a su posición original
# ─────────────────────────────────────────────────────────────
func _animar_planetas() -> void:
	var hi_oy : float = $PlanetaHielo.position.y
	var mo_oy : float = $PlanetaMorado.position.y

	# Cristal azul: arriba ↔ abajo, vuelve al centro
	var ti := create_tween()
	ti.set_loops()
	ti.set_ease(Tween.EASE_IN_OUT)
	ti.set_trans(Tween.TRANS_SINE)
	ti.tween_property($PlanetaHielo, "position:y", hi_oy - 12.0, 1.8)
	ti.tween_property($PlanetaHielo, "position:y", hi_oy,         1.4)
	ti.tween_property($PlanetaHielo, "position:y", hi_oy + 12.0, 1.8)
	ti.tween_property($PlanetaHielo, "position:y", hi_oy,         1.4)

	# Planeta morado: distinta fase
	var tm := create_tween()
	tm.set_loops()
	tm.set_ease(Tween.EASE_IN_OUT)
	tm.set_trans(Tween.TRANS_SINE)
	tm.tween_property($PlanetaMorado, "position:y", mo_oy + 14.0, 2.0).set_delay(0.8)
	tm.tween_property($PlanetaMorado, "position:y", mo_oy,          1.6)
	tm.tween_property($PlanetaMorado, "position:y", mo_oy - 14.0, 2.0)
	tm.tween_property($PlanetaMorado, "position:y", mo_oy,          1.6)

# ─────────────────────────────────────────────────────────────
#  🏷 TÍTULO — shimmer de color + chispas mágicas
# ─────────────────────────────────────────────────────────────
func _animar_titulo() -> void:
	var ts := create_tween()
	ts.set_loops()
	ts.set_ease(Tween.EASE_IN_OUT)
	ts.set_trans(Tween.TRANS_SINE)
	ts.tween_property($Titulo, "modulate", Color(1.18, 1.14, 0.90, 1.0), 1.8)
	ts.tween_property($Titulo, "modulate", Color(0.88, 0.92, 1.12, 1.0), 1.8)
	_lanzar_chispa_titulo()

func _lanzar_chispa_titulo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var simbolos := ["✨", "⭐", "✦", "★", "✧", "💫"]
	var colores  := [
		Color(1.0, 0.95, 0.3, 1.0),
		Color(0.4, 0.9,  1.0, 1.0),
		Color(1.0, 0.5,  0.9, 1.0),
		Color(0.8, 1.0,  0.5, 1.0),
		Color(1.0, 1.0,  1.0, 1.0),
	]
	for _i in range(18):
		var lbl := Label.new()
		lbl.text = simbolos[randi() % simbolos.size()]
		lbl.layout_mode = 0
		lbl.position = Vector2(
			rng.randf_range(260.0, 1100.0),
			rng.randf_range(255.0, 545.0)
		)
		lbl.add_theme_font_size_override("font_size", rng.randi_range(18, 38))
		lbl.add_theme_color_override("font_color", colores[randi() % colores.size()])
		lbl.modulate.a = 0.0
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)

		var dur   : float = rng.randf_range(0.3, 0.7)
		var delay : float = rng.randf_range(0.0, 3.0)
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(lbl, "modulate:a", 1.0, dur * 0.5).set_delay(delay)
		tw.tween_property(lbl, "modulate:a", 0.0, dur * 0.5)
		tw.tween_property(lbl, "modulate:a", 0.0, dur * 2.0)
		lbl.scale = Vector2(0.1, 0.1)
		var ts := create_tween()
		ts.set_loops()
		ts.tween_property(lbl, "scale", Vector2(1.2, 1.2), dur * 0.4).set_delay(delay)
		ts.tween_property(lbl, "scale", Vector2(0.1, 0.1), dur * 0.6)
		ts.tween_property(lbl, "scale", Vector2(0.1, 0.1), dur * 2.0)

# ─────────────────────────────────────────────────────────────
#  🟡 BOTÓN JUGAR — pulso de brillo
# ─────────────────────────────────────────────────────────────
func _animar_boton_jugar() -> void:
	var tw := create_tween()
	tw.set_loops()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property($Jugar, "modulate", Color(1.20, 1.15, 0.80, 1.0), 0.65)
	tw.tween_property($Jugar, "modulate", Color(0.88, 0.90, 1.10, 1.0), 0.65)

# ─────────────────────────────────────────────────────────────
#  ✨ ESTRELLAS — parpadean en el cielo
# ─────────────────────────────────────────────────────────────
func _crear_estrellas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in range(24):
		var lbl := Label.new()
		lbl.text = ["✦", "✧", "·", "✦", "✧"][randi() % 5]
		lbl.layout_mode = 0
		lbl.position = Vector2(rng.randf_range(20.0, 1250.0), rng.randf_range(8.0, 300.0))
		lbl.add_theme_font_size_override("font_size", rng.randi_range(10, 22))
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		var tw := create_tween()
		tw.set_loops()
		tw.set_ease(Tween.EASE_IN_OUT)
		tw.set_trans(Tween.TRANS_SINE)
		tw.tween_property(lbl, "modulate:a", 0.05, rng.randf_range(0.5, 2.2)).set_delay(rng.randf_range(0.0, 2.5))
		tw.tween_property(lbl, "modulate:a", 1.0,  rng.randf_range(0.5, 2.2))

# ─────────────────────────────────────────────────────────────
#  💧 AGUA — destellos brillantes sobre la superficie cyan
# ─────────────────────────────────────────────────────────────
func _efecto_agua() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var simbolos := ["◈", "✦", "◇", "✧", "⬡", "◈"]
	var paleta := [
		Color(1.0, 1.0, 1.0, 1.0),
		Color(0.3, 0.95, 1.0, 1.0),
		Color(0.6, 1.0,  1.0, 1.0),
		Color(1.0, 0.97, 0.5, 1.0),
	]
	for _i in range(22):
		var lbl := Label.new()
		lbl.text = simbolos[randi() % simbolos.size()]
		lbl.layout_mode = 0
		lbl.position = Vector2(rng.randf_range(5.0, 240.0), rng.randf_range(595.0, 755.0))
		lbl.add_theme_font_size_override("font_size", rng.randi_range(16, 32))
		lbl.add_theme_color_override("font_color", paleta[randi() % paleta.size()])
		lbl.modulate.a = 0.0
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)

		var dur   : float = rng.randf_range(0.25, 0.8)
		var delay : float = rng.randf_range(0.0, 2.5)
		var tw := create_tween()
		tw.set_loops()
		tw.tween_property(lbl, "modulate:a", 1.0, dur * 0.4).set_delay(delay)
		tw.tween_property(lbl, "modulate:a", 0.0, dur * 0.6)
		tw.tween_property(lbl, "modulate:a", 0.0, dur * 1.5)

		# Deriva horizontal relativa a la posición original del label
		var px : float = lbl.position.x
		var tm := create_tween()
		tm.set_loops()
		tm.set_ease(Tween.EASE_IN_OUT)
		tm.set_trans(Tween.TRANS_SINE)
		tm.tween_property(lbl, "position:x", px + rng.randf_range(6.0, 18.0), 1.8).set_delay(delay)
		tm.tween_property(lbl, "position:x", px, 1.8)

# ─────────────────────────────────────────────────────────────
#  🎬 TRANSICIÓN — fade negro al cambiar escena
# ─────────────────────────────────────────────────────────────
func _on_jugar_presionado() -> void:
	$Jugar.disabled = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_overlay, "color:a", 1.0, 0.5)
	tw.tween_callback(func():
		TransitionManager.cambiar_escena("res://scenes/Diagnostico.tscn")
	)

# ─────────────────────────────────────────────────────────────
#  AJUSTES
# ─────────────────────────────────────────────────────────────
func _on_ajustes_presionado() -> void:
	$PanelAjustes.visible = true

func _on_cerrar_ajustes() -> void:
	$PanelAjustes.visible = false

func _on_volumen_presionado() -> void:
	var muteado = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, not muteado)
	if AudioServer.is_bus_mute(0):
		$PanelAjustes/BtnVolumen.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		$PanelAjustes/BtnVolumen.modulate = Color(1, 1, 1, 1)

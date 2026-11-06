extends Node

# ═══════════════════════════════════════════════════════════════
#  DIPLOMA / CONSTANCIA DE LOGRO — MATI EVOLUCIÓN
#  mostrar(parent, nombre, volver_cb) → overlay en pantalla
#  Al pulsar "Descargar PDF" genera un .html estilizado y lo abre
#  en el navegador para que el usuario imprima / guarde como PDF.
# ═══════════════════════════════════════════════════════════════

static func mostrar(parent: Node, nombre_jugador: String, volver_cb: Callable = Callable()) -> void:
	# ── Overlay oscuro ──────────────────────────────────────────
	var overlay := ColorRect.new()
	overlay.name         = "OverlayDiploma"
	overlay.color        = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index      = 200
	parent.add_child(overlay)

	# ── Panel central ───────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position  = Vector2(-520, -340)
	panel.size      = Vector2(1040, 680)
	panel.modulate.a = 0.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.03, 0.18)
	sb.border_color = Color(0.95, 0.78, 0.1)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	sb.content_margin_left   = 48
	sb.content_margin_right  = 48
	sb.content_margin_top    = 32
	sb.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", sb)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Deco top
	var deco_top := Label.new()
	deco_top.text = "★  ✦  ★  ✦  ★  ✦  ★  ✦  ★  ✦  ★  ✦  ★"
	deco_top.add_theme_font_size_override("font_size", 16)
	deco_top.add_theme_color_override("font_color", Color(0.95, 0.78, 0.1))
	deco_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(deco_top)

	# Título
	var lbl_titulo := Label.new()
	lbl_titulo.text = "CONSTANCIA DE LOGRO"
	lbl_titulo.add_theme_font_size_override("font_size", 42)
	lbl_titulo.add_theme_color_override("font_color",        Color(0.95, 0.78, 0.1))
	lbl_titulo.add_theme_color_override("font_shadow_color", Color(0.3, 0.0, 0.6))
	lbl_titulo.add_theme_constant_override("shadow_offset_x", 3)
	lbl_titulo.add_theme_constant_override("shadow_offset_y", 3)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_titulo)

	var lbl_sub := Label.new()
	lbl_sub.text = "Mati Evolución  —  Aprendizaje de Matemáticas"
	lbl_sub.add_theme_font_size_override("font_size", 18)
	lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.95))
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_sub)

	# Separador
	var sep := Label.new()
	sep.text = "─────────────────────────────────────────────────"
	sep.add_theme_font_size_override("font_size", 12)
	sep.add_theme_color_override("font_color", Color(0.4, 0.3, 0.6))
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sep)

	var lbl_oto := Label.new()
	lbl_oto.text = "Se otorga la presente constancia a:"
	lbl_oto.add_theme_font_size_override("font_size", 20)
	lbl_oto.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	lbl_oto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_oto)

	# Nombre del jugador (destacado)
	var lbl_nombre := Label.new()
	lbl_nombre.text = nombre_jugador
	lbl_nombre.add_theme_font_size_override("font_size", 60)
	lbl_nombre.add_theme_color_override("font_color",        Color(0.35, 0.9, 1.0))
	lbl_nombre.add_theme_color_override("font_shadow_color", Color(0.0, 0.3, 0.6))
	lbl_nombre.add_theme_constant_override("shadow_offset_x", 3)
	lbl_nombre.add_theme_constant_override("shadow_offset_y", 3)
	lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_nombre)

	# Logro
	var lbl_logro := Label.new()
	lbl_logro.text = "Por haber completado los 3 planetas de\nMati Evolución dominando suma, resta y tablas de multiplicar."
	lbl_logro.add_theme_font_size_override("font_size", 22)
	lbl_logro.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl_logro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_logro)

	# Fecha
	var fecha := Time.get_datetime_dict_from_system()
	var lbl_fecha := Label.new()
	lbl_fecha.text = "Fecha: %02d/%02d/%04d" % [fecha["day"], fecha["month"], fecha["year"]]
	lbl_fecha.add_theme_font_size_override("font_size", 17)
	lbl_fecha.add_theme_color_override("font_color", Color(0.65, 0.65, 0.75))
	lbl_fecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_fecha)

	# Deco bottom
	var deco_bot := Label.new()
	deco_bot.text = "★  ✦  ★  ✦  ★  ✦  ★  ✦  ★  ✦  ★  ✦  ★"
	deco_bot.add_theme_font_size_override("font_size", 16)
	deco_bot.add_theme_color_override("font_color", Color(0.95, 0.78, 0.1))
	deco_bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(deco_bot)

	# ── Botones ─────────────────────────────────────────────────
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)

	var btn_pdf := Button.new()
	btn_pdf.text = "⬇  Descargar diploma (PDF)"
	btn_pdf.add_theme_font_size_override("font_size", 17)
	btn_pdf.custom_minimum_size = Vector2(280, 44)
	var sb_pdf := StyleBoxFlat.new()
	sb_pdf.bg_color = Color(0.2, 0.55, 0.9)
	sb_pdf.set_corner_radius_all(8)
	btn_pdf.add_theme_stylebox_override("normal", sb_pdf)
	var sb_pdf_h := sb_pdf.duplicate() as StyleBoxFlat
	sb_pdf_h.bg_color = Color(0.3, 0.65, 1.0)
	btn_pdf.add_theme_stylebox_override("hover", sb_pdf_h)
	btn_pdf.pressed.connect(func(): _generar_pdf(nombre_jugador))
	hbox.add_child(btn_pdf)

	if volver_cb.is_valid():
		var btn_volver := Button.new()
		btn_volver.text = "▶  Volver al Mundo 3"
		btn_volver.add_theme_font_size_override("font_size", 17)
		btn_volver.custom_minimum_size = Vector2(210, 44)
		var sb_v := StyleBoxFlat.new()
		sb_v.bg_color = Color(0.2, 0.65, 0.35)
		sb_v.set_corner_radius_all(8)
		btn_volver.add_theme_stylebox_override("normal", sb_v)
		var sb_vh := sb_v.duplicate() as StyleBoxFlat
		sb_vh.bg_color = Color(0.3, 0.78, 0.45)
		btn_volver.add_theme_stylebox_override("hover", sb_vh)
		btn_volver.pressed.connect(func():
			overlay.queue_free()
			volver_cb.call()
		)
		hbox.add_child(btn_volver)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "✕  Cerrar"
	btn_cerrar.add_theme_font_size_override("font_size", 17)
	btn_cerrar.custom_minimum_size = Vector2(130, 44)
	var sb_c := StyleBoxFlat.new()
	sb_c.bg_color = Color(0.45, 0.18, 0.18)
	sb_c.set_corner_radius_all(8)
	btn_cerrar.add_theme_stylebox_override("normal", sb_c)
	var sb_ch := sb_c.duplicate() as StyleBoxFlat
	sb_ch.bg_color = Color(0.6, 0.25, 0.25)
	btn_cerrar.add_theme_stylebox_override("hover", sb_ch)
	btn_cerrar.pressed.connect(func(): overlay.queue_free())
	hbox.add_child(btn_cerrar)

	# ── Animación entrada ────────────────────────────────────────
	var tw := overlay.create_tween()
	tw.set_parallel(false)
	tw.tween_property(overlay, "color", Color(0, 0, 0, 0.78), 0.28)
	tw.tween_property(panel,   "modulate:a", 1.0, 0.35)

# ─────────────────────────────────────────────────────────────
#  GENERACIÓN DE HTML ESTILIZADO → abre en navegador → PDF
# ─────────────────────────────────────────────────────────────
static func _generar_pdf(nombre: String) -> void:
	if OS.get_name() == "Web":
		# En web: usamos la API de impresión del navegador
		var js_print := """
(function(){
  var w = window.open('', '_blank', 'width=800,height=600');
  w.document.write(`%s`);
  w.document.close();
  w.focus();
  setTimeout(function(){ w.print(); }, 600);
})();
""" % _html_diploma(nombre)
		JavaScriptBridge.eval(js_print)
	else:
		# En escritorio: generar .html con nombre del jugador y abrir en navegador
		var nombre_limpio := nombre.strip_edges().replace(" ", "_").to_lower()
		var ruta := "user://diploma_%s.html" % nombre_limpio
		var archivo := FileAccess.open(ruta, FileAccess.WRITE)
		if archivo:
			archivo.store_string(_html_diploma(nombre))
			archivo.close()
			OS.shell_open(ProjectSettings.globalize_path(ruta))

static func _html_diploma(nombre: String) -> String:
	var fecha := Time.get_datetime_dict_from_system()
	var fecha_str := "%02d/%02d/%04d" % [fecha["day"], fecha["month"], fecha["year"]]
	return """<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Diploma - %s</title>
<style>
  @page { size: A4 landscape; margin: 1.5cm; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: 'Segoe UI', Arial, sans-serif;
    background: #0d0520;
    color: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    padding: 20px;
  }
  .diploma {
    background: linear-gradient(145deg, #0d0520 0%%, #1a0840 50%%, #0d0520 100%%);
    border: 6px solid #f2c410;
    border-radius: 24px;
    padding: 50px 70px;
    max-width: 900px;
    width: 100%%;
    text-align: center;
    box-shadow: 0 0 60px rgba(150,80,255,0.5), inset 0 0 40px rgba(80,0,150,0.3);
  }
  .estrellas {
    font-size: 18px;
    color: #f2c410;
    letter-spacing: 4px;
    margin-bottom: 12px;
  }
  .titulo {
    font-size: 48px;
    font-weight: 900;
    color: #f2c410;
    text-shadow: 0 0 20px rgba(242,196,16,0.7), 3px 3px 0 #3a0a80;
    letter-spacing: 4px;
    margin-bottom: 6px;
  }
  .subtitulo {
    font-size: 18px;
    color: #b0b0e0;
    margin-bottom: 20px;
    font-style: italic;
  }
  .separador {
    border: none;
    height: 2px;
    background: linear-gradient(to right, transparent, #f2c410, transparent);
    margin: 16px auto;
    width: 80%%;
  }
  .otorga {
    font-size: 20px;
    color: #d0d0f0;
    margin-bottom: 12px;
  }
  .nombre {
    font-size: 64px;
    font-weight: 900;
    color: #40e0ff;
    text-shadow: 0 0 24px rgba(64,224,255,0.6), 3px 3px 0 #003860;
    margin: 8px 0 18px;
    letter-spacing: 2px;
  }
  .logro {
    font-size: 20px;
    color: #ffffff;
    line-height: 1.6;
    max-width: 640px;
    margin: 0 auto 20px;
  }
  .logro strong { color: #f2c410; }
  .fecha {
    font-size: 16px;
    color: #888;
    margin-bottom: 16px;
  }
  .sello {
    display: inline-block;
    border: 3px solid #f2c410;
    border-radius: 50%%;
    width: 90px; height: 90px;
    line-height: 84px;
    font-size: 40px;
    margin: 8px;
    box-shadow: 0 0 16px rgba(242,196,16,0.4);
  }
  @media print {
    body { background: #0d0520; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .no-print { display: none; }
  }
</style>
</head>
<body>
<div class="diploma">
  <div class="estrellas">★ ✦ ★ ✦ ★ ✦ ★ ✦ ★ ✦ ★ ✦ ★</div>
  <div class="titulo">CONSTANCIA DE LOGRO</div>
  <div class="subtitulo">Mati Evolución &mdash; Aprendizaje de Matemáticas</div>
  <hr class="separador">
  <div class="otorga">Se otorga la presente constancia a:</div>
  <div class="nombre">%s</div>
  <div class="logro">
    Por haber completado los <strong>3 planetas</strong> de Mati Evolución,<br>
    demostrando dominio en <strong>suma</strong>, <strong>resta</strong> y <strong>tablas de multiplicar</strong>.
  </div>
  <div class="fecha">Fecha: %s</div>
  <hr class="separador">
  <div class="estrellas">★ ✦ ★ ✦ ★ ✦ ★ ✦ ★ ✦ ★ ✦ ★</div>
  <br>
  <button class="no-print"
    style="margin-top:16px;padding:12px 32px;font-size:18px;background:#1a6fc4;color:#fff;border:none;border-radius:8px;cursor:pointer;"
    onclick="window.print()">🖨  Imprimir / Guardar como PDF</button>
</div>
</body>
</html>""" % [nombre, nombre, fecha_str]

extends Control

# ═══════════════════════════════════════════════════════════════
#  VISOR DE HISTORIA — Libro de ilustraciones de Mati Evolución
#  7 páginas animadas, toca para avanzar, X para cerrar.
# ═══════════════════════════════════════════════════════════════

const PAGINAS : Array = [
	"res://assets/historia/historia_0.jpeg",
	"res://assets/historia/historia_1.jpeg",
	"res://assets/historia/historia_2.jpeg",
	"res://assets/historia/historia_3.jpeg",
	"res://assets/historia/historia_4.jpeg",
	"res://assets/historia/historia_5.jpeg",
	"res://assets/historia/historia_6.jpeg",
]

var pagina_actual : int = 0
var _img          : TextureRect = null
var _label_pag    : Label       = null
var _btn_cerrar   : Button      = null
var _btn_prev     : Button      = null
var _btn_next     : Button      = null
var _overlay_toca : Label       = null
var _transicionando : bool      = false

# Escena desde la que se llegó (para volver)
var escena_origen : String = "res://scenes/Mapa.tscn"

func _ready() -> void:
	_construir_ui()
	_mostrar_pagina(0, false)
	set_process_input(true)

# ─────────────────────────────────────────────────────────────
#  CONSTRUCCIÓN DE LA UI
# ─────────────────────────────────────────────────────────────
func _construir_ui() -> void:
	# Fondo negro total
	var fondo := ColorRect.new()
	fondo.color = Color(0.04, 0.02, 0.08)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fondo)

	# Imagen de la página (centrada y escalada)
	_img = TextureRect.new()
	_img.layout_mode  = 0
	_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_img.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_img)

	# Botón cerrar — esquina superior derecha
	_btn_cerrar = Button.new()
	_btn_cerrar.text = "✕"
	_btn_cerrar.layout_mode = 0
	_btn_cerrar.position = Vector2(1200.0, 12.0)
	_btn_cerrar.size     = Vector2(68.0, 52.0)
	_btn_cerrar.add_theme_font_size_override("font_size", 26)
	_btn_cerrar.add_theme_color_override("font_color", Color(1, 1, 1, 0.90))
	var st_c := StyleBoxFlat.new()
	st_c.bg_color = Color(0.0, 0.0, 0.0, 0.55)
	st_c.corner_radius_top_left     = 12
	st_c.corner_radius_top_right    = 12
	st_c.corner_radius_bottom_left  = 12
	st_c.corner_radius_bottom_right = 12
	_btn_cerrar.add_theme_stylebox_override("normal",  st_c)
	_btn_cerrar.add_theme_stylebox_override("hover",   st_c)
	_btn_cerrar.add_theme_stylebox_override("pressed", st_c)
	_btn_cerrar.pressed.connect(_cerrar)
	add_child(_btn_cerrar)

	# Indicador de página — esquina inferior centro
	_label_pag = Label.new()
	_label_pag.layout_mode = 0
	_label_pag.position    = Vector2(560.0, 686.0)
	_label_pag.size        = Vector2(160.0, 30.0)
	_label_pag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_pag.add_theme_font_size_override("font_size", 18)
	_label_pag.add_theme_color_override("font_color", Color(1, 1, 1, 0.70))
	add_child(_label_pag)

	# Botón página anterior — izquierda
	_btn_prev = Button.new()
	_btn_prev.text = "‹"
	_btn_prev.layout_mode = 0
	_btn_prev.position = Vector2(8.0, 310.0)
	_btn_prev.size     = Vector2(52.0, 100.0)
	_btn_prev.add_theme_font_size_override("font_size", 36)
	_btn_prev.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	var st_nav := StyleBoxFlat.new()
	st_nav.bg_color = Color(0.0, 0.0, 0.0, 0.45)
	st_nav.corner_radius_top_left     = 10
	st_nav.corner_radius_top_right    = 10
	st_nav.corner_radius_bottom_left  = 10
	st_nav.corner_radius_bottom_right = 10
	_btn_prev.add_theme_stylebox_override("normal",  st_nav)
	_btn_prev.add_theme_stylebox_override("hover",   st_nav)
	_btn_prev.add_theme_stylebox_override("pressed", st_nav)
	_btn_prev.pressed.connect(_pagina_anterior)
	add_child(_btn_prev)

	# Botón página siguiente — derecha
	_btn_next = Button.new()
	_btn_next.text = "›"
	_btn_next.layout_mode = 0
	_btn_next.position = Vector2(1220.0, 310.0)
	_btn_next.size     = Vector2(52.0, 100.0)
	_btn_next.add_theme_font_size_override("font_size", 36)
	_btn_next.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_btn_next.add_theme_stylebox_override("normal",  st_nav)
	_btn_next.add_theme_stylebox_override("hover",   st_nav)
	_btn_next.add_theme_stylebox_override("pressed", st_nav)
	_btn_next.pressed.connect(_pagina_siguiente)
	add_child(_btn_next)

	# Hint "toca para continuar" — aparece al final de la animación
	_overlay_toca = Label.new()
	_overlay_toca.text = "▸ Toca para continuar"
	_overlay_toca.layout_mode = 0
	_overlay_toca.position = Vector2(480.0, 650.0)
	_overlay_toca.add_theme_font_size_override("font_size", 18)
	_overlay_toca.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5, 0.88))
	_overlay_toca.visible = false
	add_child(_overlay_toca)

# ─────────────────────────────────────────────────────────────
#  MOSTRAR PÁGINA
# ─────────────────────────────────────────────────────────────
func _mostrar_pagina(idx: int, animar: bool = true) -> void:
	pagina_actual = clamp(idx, 0, PAGINAS.size() - 1)
	var ruta = PAGINAS[pagina_actual]

	_overlay_toca.visible = false

	if ResourceLoader.exists(ruta):
		_img.texture = load(ruta)
	else:
		_img.texture = null

	_label_pag.text = str(pagina_actual + 1) + " / " + str(PAGINAS.size())

	# Visibilidad de navegación
	_btn_prev.visible = pagina_actual > 0
	var es_ultima = pagina_actual >= PAGINAS.size() - 1
	_btn_next.visible = not es_ultima

	if animar:
		_img.modulate = Color(1, 1, 1, 0.0)
		var tw := create_tween()
		tw.tween_property(_img, "modulate:a", 1.0, 0.35)
		tw.tween_callback(func():
			_overlay_toca.visible = true
			_transicionando = false
		)
		_transicionando = true
	else:
		_img.modulate = Color(1, 1, 1, 1)
		_overlay_toca.visible = true
		_transicionando = false

	# En la última página el hint cambia
	if es_ultima:
		_overlay_toca.text = "▸ Toca para cerrar"
	else:
		_overlay_toca.text = "▸ Toca para continuar"

# ─────────────────────────────────────────────────────────────
#  NAVEGACIÓN
# ─────────────────────────────────────────────────────────────
func _pagina_siguiente() -> void:
	if _transicionando: return
	if pagina_actual < PAGINAS.size() - 1:
		_mostrar_pagina(pagina_actual + 1)
	else:
		_cerrar()

func _pagina_anterior() -> void:
	if _transicionando: return
	if pagina_actual > 0:
		_mostrar_pagina(pagina_actual - 1)

func _cerrar() -> void:
	TransitionManager.cambiar_escena(escena_origen)

# ─────────────────────────────────────────────────────────────
#  INPUT — toca en cualquier lugar para avanzar
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# No avanzar si el clic fue sobre un botón de control
		if _btn_cerrar.get_rect().has_point(event.position): return
		if _btn_prev.visible and _btn_prev.get_rect().has_point(event.position): return
		if _btn_next.visible and _btn_next.get_rect().has_point(event.position): return
		_pagina_siguiente()

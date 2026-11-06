extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MUNDO 2 — PLANETA DE HIELO
#  El jugador recorre el mundo y habla con 5 NPCs.
#  Cada NPC tiene su historia y su desafío matemático propio.
#  No existe pantalla de selección de secciones.
# ═══════════════════════════════════════════════════════════════

const VELOCIDAD        : float = 280.0
const DIST_INTERACCION : float = 280.0

const LIMITE_IZQ  : float = -2030.0
const LIMITE_DER  : float =  2680.0
const LIMITE_ARR  : float =   730.0
const LIMITE_ABA  : float =   930.0

const RUTA_SAVE : String = "user://mati_save.json"

# ─────────────────────────────────────────────────────────────
#  DATOS DE LOS 5 NPCs DEL MUNDO 2
#  seccion: ID del desafío (6–10), mismo que el sistema de guardado
# ─────────────────────────────────────────────────────────────
const NPCS_DATA : Array = [
	{
		"id":            "muneco",
		"nombre":        "Muñeco",
		"seccion":       6,
		"pos":           Vector2(-1800, 760),   # Zona izquierda — pista de hielo
		"textura":       "res://assets/npcs/Hombre de nieve.PNG",
		"dialogo":       "¡Brrr, brrr! Soy Muñeco de Nieve.\nMi iglú se está derritiendo y\nnecesito sumar bloques de hielo\npara reconstruirlo. ¡Números grandes!",
		"dialogo_hecho": "¡Mi iglú está completo!\nGracias Mati, ya no tengo frío."
	},
	{
		"id":            "cristal",
		"nombre":        "Polar",
		"seccion":       7,
		"pos":           Vector2(-900, 780),
		"textura":       "res://assets/npcs/Astronauta de la nieve.PNG",
		"dialogo":       "¡Brrr! Soy Polar, explorador ártico.\nTenía muchos bloques de hielo\npero se están derritiendo uno a uno...\nNecesito RESTAR para saber\ncuántos me quedan. ¿Me ayudas?",
		"dialogo_hecho": "¡Mis bloques están contados!\n¡Gracias Mati, eres genial!\nAhora sé exactamente cuántos\nbloques me quedan."
	},
	{
		"id":            "kiro",
		"nombre":        "Kiro",
		"seccion":       8,
		"pos":           Vector2(400, 830),     # Centro del mundo — zona baja
		"textura":       "res://assets/npcs/Niño azul.PNG",
		"dialogo":       "¡Hiya! Soy Kiro el ninja del hielo.\nMi entrenamiento usa multiplicaciones.\n¿Conoces la tabla del 1?\n¡Demuéstramelo, guerrero!",
		"dialogo_hecho": "¡Impresionante, guerrero!\nTu conocimiento de la tabla del 1\nes digno de un ninja."
	},
	{
		"id":            "maestra_neva",
		"nombre":        "Maestra Neva",
		"seccion":       9,
		"pos":           Vector2(1800, 790),    # Derecha-centro — zona alta, sobre el hielo
		"textura":       "res://assets/npcs/Chica pelo verde.PNG",
		"dialogo":       "Buenos días, estudiante...\nSoy Maestra Neva.\nPara cruzar mi puente de hielo\ndebes dominar la tabla del 2.",
		"dialogo_hecho": "¡Excelente estudiante!\nLa tabla del 2 ya no tiene\nsecretos para ti. ¡Bien hecho!"
	},
	{
		"id":            "mora",
		"nombre":        "Mora",
		"seccion":       10,
		"pos":           Vector2(1050, 900),    # Centro-derecha, lejos del robot final
		"textura":       "res://assets/npcs/Alíen morada.PNG",
		"dialogo":       "¡Yo soy Mora, guardiana del portal!\nNadie cruza sin antes resolver\nmis multiplicaciones mixtas.\n¿Te atreves?",
		"dialogo_hecho": "Impresionante, Mati.\nPocas veces alguien supera\nmis desafíos. ¡El portal es tuyo!"
	},
	{
		"id":            "robot",
		"nombre":        "ROBO-X",
		"seccion":       20,
		"pos":           Vector2(2300, 880),    # Extremo derecho, mas hacia el centro — el último guardián
		"escala":        1.6,
		"textura":       "res://assets/npcs/robot_villano.PNG",
		"dialogo":       "ERROR... ERROR...\n¡INTRUSO DETECTADO!\nSoy ROBO-X, guardián mecánico\ndel Planeta de Hielo.\nDerrótame resolviendo mis\ncálculos o TE CONGELO.",
		"dialogo_hecho": "CALCULO INCORRECTO...\nPROCESANDO...\n¡ME HAS VENCIDO!\nTus habilidades matemáticas\nsuperan mi programación.\nPuedes pasar, Mati."
	}
]

const SKINS_VISTAS = {
	"default": {
		"frente":  "res://assets/personajes/mati_frente.PNG",
		"perfil":  "res://assets/personajes/mati_perfil.PNG",
		"espalda": "res://assets/personajes/mati_espalda.PNG",
	},
	"fachero": {
		"frente":  "res://assets/personajes/mati_fachero.PNG",
		"perfil":  "res://assets/personajes/mati_fachero_perfil.PNG",
		"espalda": "res://assets/personajes/mati_fachero_espalda.PNG",
	},
	"ninja": {
		"frente":  "res://assets/personajes/mati_ninja.PNG",
		"perfil":  "res://assets/personajes/mati_ninja_perfil.PNG",
		"espalda": "res://assets/personajes/mati_ninja_espalda.PNG",
	},
	"escolar": {
		"frente":  "res://assets/personajes/mati_escolar.PNG",
		"perfil":  "res://assets/personajes/mati_escolar_perfil.PNG",
		"espalda": "res://assets/personajes/mati_escolar_espalda.PNG",
	},
	"joven": {
		"frente":  "res://assets/personajes/mati_joven.PNG",
		"perfil":  "res://assets/personajes/mati_joven_perfil.PNG",
		"espalda": "res://assets/personajes/mati_joven_espalda.PNG",
	},
	"lentes": {
		"frente":  "res://assets/personajes/mati_lentes.PNG",
		"perfil":  "res://assets/personajes/mati_lentes_perfil.PNG",
		"espalda": "res://assets/personajes/mati_lentes.PNG",
	},
}

# ── Estado general ────────────────────────────────────────────
var guardado_node
var monedas_sesion    : int   = 0
var mision_completada : bool  = false
var animacion_lista   : bool  = true   # Sin animación de entrada en Mundo 2
var dialogo_activo    : bool  = false
var texto_completo    : bool  = false
var texto_timer       : float = 0.0
var texto_indice      : int   = 0
var texto_npc_actual  : String = ""
const VELOCIDAD_TEXTO : float = 0.04

var dir_x : float = 0.0
var dir_y : float = 0.0

# ── Vistas direccionales de Mati ──────────────────────────────
var _skin_vistas : Dictionary = {}
var _dir_actual  : String = "frente"
var _flip_perfil : bool   = false

# ── NPCs ──────────────────────────────────────────────────────
var nubes_nodo          : Node2D      = null
var npc_nodes           : Array       = []
var npc_cercano         : int         = -1
var npc_activo          : int         = -1
var npc_cercano_prev    : int         = -1
var npc_base_pos        : Array       = []
var tiempo_mundo        : float       = 0.0
var btn_era_visible     : bool        = false
var btn_escala_orig     : Vector2     = Vector2(0.07508756, 0.06985476)
var indicador_estrella  : TextureRect = null
var indicador_wrap_node : Control     = null
var indicador_label0    : Label       = null

# ── Diálogo RPG (portraits + overlay) ────────────────────────
var _rpg_layer       : CanvasLayer   = null
var _rpg_bg          : ColorRect     = null
var _rpg_mati_ret    : TextureRect   = null
var _rpg_npc_ret     : TextureRect   = null
var _rpg_dlg_box     : Control       = null
var _rpg_lbl_nom     : Label         = null
var _rpg_lbl_txt     : Label         = null
var _rpg_btn_ayd     : TextureButton = null
var _rpg_lbl_cls     : Label         = null
var _rpg_estrellas   : Array         = []
var _rpg_mati_dest_x : float         = 0.0
var _rpg_npc_dest_x  : float         = 0.0

# ─────────────────────────────────────────────────────────────
#  INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	guardado_node = load("res://scripts/guardado.gd").new()
	var datos = guardado_node.cargar()

	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").musica_explorar_mundo(2)

	monedas_sesion = int(datos.get("monedas", 0))
	$UI/LabelMonedas.visible = false
	_crear_indicador_estrella($UI, Vector2(10.0, 8.0))
	_actualizar_label_monedas()

	mision_completada = _todas_secciones_completas()
	btn_escala_orig = $BtnInteractuar.scale   # guardar escala original del scene
	$BtnInteractuar.visible = false
	$BtnInteractuar.z_index = 500  # el botón ! siempre delante de todo

	# Aplicar skin del jugador (con escala normalizada)
	var skin_id = datos.get("skin_activa", "default")
	_aplicar_skin(skin_id)

	# Crear NPCs programáticamente
	_crear_npcs()
	_actualizar_visual_npcs()

	# Actualizar portal (encendido/apagado según progreso)
	_actualizar_portal()

	# Revelar ROBO-X si ya se desbloqueó
	_intentar_revelar_robot()

	# Nubes animadas (tonos fríos para el planeta de hielo)
	$Fondo.z_index = -2
	nubes_nodo = Node2D.new()
	nubes_nodo.set_script(load("res://scripts/efectos_nubes_hielo.gd"))
	add_child(nubes_nodo)

	# Efectos de hielo flotantes (copos, cristales)
	var efectos_hielo := Node2D.new()
	efectos_hielo.set_script(load("res://scripts/efectos_ambiente_hielo.gd"))
	efectos_hielo.z_index = -1
	add_child(efectos_hielo)

	# Botones de dirección
	$UI/BtnArriba.button_down.connect(func(): dir_y = -1.0)
	$UI/BtnArriba.button_up.connect(func(): dir_y = 0.0)
	$UI/BtnAbajo.button_down.connect(func(): dir_y = 1.0)
	$UI/BtnAbajo.button_up.connect(func(): dir_y = 0.0)
	$UI/BtnIzquierda.button_down.connect(func(): dir_x = -1.0)
	$UI/BtnIzquierda.button_up.connect(func(): dir_x = 0.0)
	$UI/BtnDerecha.button_down.connect(func(): dir_x = 1.0)
	$UI/BtnDerecha.button_up.connect(func(): dir_x = 0.0)

	set_process_input(true)

	$BtnInteractuar.pressed.connect(_on_btn_interactuar)

	# Pausa
	$UI/BtnAjustes.pressed.connect(_toggle_pausa)
	$UI/PanelPausa/BtnContinuar.pressed.connect(_toggle_pausa)
	$UI/PanelPausa/BtnSalir.pressed.connect(_ir_al_mapa)
	$UI/PanelPausa/BtnVolumen.pressed.connect(_on_volumen_presionado)
	_actualizar_icono_volumen()
	$UI/PanelPausa.visible = false

	# Panel de diálogo — se oculta permanentemente; usamos el sistema RPG
	$UI/PanelDialogo.visible = false
	$UI/PanelDialogo/BtnAyudar.visible = false
	$UI/PanelDialogo/BtnAyudar.pressed.connect(_iniciar_desafio)
	_configurar_panel_dialogo()
	_crear_rpg_layer()   # ← sistema de diálogo estilo RPG

	# Monedas dispersas
	for moneda in get_tree().get_nodes_in_group("moneda"):
		moneda.body_entered.connect(_on_moneda_recolectada.bind(moneda))

	# Zona portal original (mantener sin usarla)
	if has_node("ZonaCohete"):
		$ZonaCohete.body_entered.connect(func(_b): pass)
		$ZonaCohete.body_exited.connect(func(_b): pass)

# ─────────────────────────────────────────────────────────────
#  CREAR NPCs EN EL MUNDO 2D
# ─────────────────────────────────────────────────────────────
var label_npc_nombre : Label = null

func _crear_npcs() -> void:
	var npc_script = load("res://scripts/npc_personaje.gd")
	for npc_data in NPCS_DATA:
		var npc = Node2D.new()
		npc.set_script(npc_script)
		npc.position = npc_data["pos"]
		if npc_data.has("escala"):
			var e : float = float(npc_data["escala"])
			npc.scale = Vector2(e, e)
		npc.z_index = 5   # NPCs siempre delante de Mati
		add_child(npc)
		var tex : Texture2D = null
		var es_robot : bool = (npc_data.get("id", "") == "robot")
		if not es_robot and ResourceLoader.exists(npc_data["textura"]):
			tex = load(npc_data["textura"])
		npc.setup(tex)
		var completado = guardado_node.seccion_completada(npc_data["seccion"])
		npc.marcar_completado(completado)
		if es_robot:
			npc.visible = false   # oculto hasta completar los otros NPCs
		npc_nodes.append(npc)
		npc_base_pos.append(npc_data["pos"])


	label_npc_nombre = Label.new()
	label_npc_nombre.add_theme_font_size_override("font_size", 20)
	label_npc_nombre.add_theme_color_override("font_color", Color.WHITE)
	label_npc_nombre.add_theme_color_override("font_shadow_color", Color.BLACK)
	label_npc_nombre.add_theme_constant_override("shadow_offset_x", 2)
	label_npc_nombre.add_theme_constant_override("shadow_offset_y", 2)
	label_npc_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_npc_nombre.position = Vector2(490, 530)
	label_npc_nombre.size     = Vector2(300, 30)
	label_npc_nombre.visible  = false
	$UI.add_child(label_npc_nombre)

func _actualizar_visual_npcs() -> void:
	for i in range(npc_nodes.size()):
		var completada = guardado_node.seccion_completada(NPCS_DATA[i]["seccion"])
		npc_nodes[i].marcar_completado(completada)

# ─────────────────────────────────────────────────────────────
#  PORTAL DE HIELO (encendido cuando todas las secciones están hechas)
# ─────────────────────────────────────────────────────────────
func _actualizar_portal() -> void:
	if has_node("SpriteAstronauta"):
		$SpriteAstronauta.visible = false

# ─────────────────────────────────────────────────────────────
#  ROBOT — se desbloquea al completar las 5 secciones previas
# ─────────────────────────────────────────────────────────────
func _robot_bloqueado() -> bool:
	for sec in [6, 7, 8, 9, 10]:
		if not guardado_node.seccion_completada(sec):
			return true
	return false

func _intentar_revelar_robot() -> void:
	var idx : int = -1
	for i in range(NPCS_DATA.size()):
		if NPCS_DATA[i].get("id", "") == "robot":
			idx = i
			break
	if idx == -1:
		return

	var completado : bool = guardado_node.seccion_completada(NPCS_DATA[idx]["seccion"])
	if completado:
		# Ya fue vencido — mostrarlo directo con check
		npc_nodes[idx].visible = true
		var tex_r = load(NPCS_DATA[idx]["textura"]) if ResourceLoader.exists(NPCS_DATA[idx]["textura"]) else null
		npc_nodes[idx].setup(tex_r)
		npc_nodes[idx].marcar_completado(true)
		return
	if _robot_bloqueado():
		npc_nodes[idx].visible = false
		return

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(npc_nodes[idx]):
		_animar_aparicion_robot(npc_nodes[idx], idx)

func _animar_aparicion_robot(npc: Node2D, idx: int) -> void:
	var tex_r = load(NPCS_DATA[idx]["textura"]) if ResourceLoader.exists(NPCS_DATA[idx]["textura"]) else null
	npc.setup(tex_r)
	npc.visible   = true
	npc.modulate  = Color(1, 1, 1, 0)
	var escala_final : Vector2 = npc.scale
	npc.scale = escala_final * 0.3

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(npc, "modulate:a", 1.0,         0.5)
	tw.tween_property(npc, "scale",      escala_final, 0.6)

	# Banner "¡INTRUSO DETECTADO!"
	var vp   := get_viewport().get_visible_rect().size
	var banner := Label.new()
	banner.text = "⚠ INTRUSO DETECTADO ⚠"
	banner.add_theme_font_size_override("font_size", 52)
	banner.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	banner.add_theme_constant_override("shadow_offset_x", 3)
	banner.add_theme_constant_override("shadow_offset_y", 3)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	banner.size        = Vector2(vp.x, 90)
	banner.position    = Vector2(0, vp.y * 0.45)
	banner.pivot_offset = banner.size * 0.5
	banner.modulate    = Color(1, 1, 1, 0)
	banner.scale       = Vector2(1.5, 1.5)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index     = 100
	$UI.add_child(banner)

	var tb := create_tween()
	tb.set_parallel(true)
	tb.tween_property(banner, "modulate:a", 1.0,           0.25)
	tb.tween_property(banner, "scale",      Vector2(1,1),  0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tb.chain().tween_interval(1.2)
	tb.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	tb.chain().tween_callback(func(): banner.queue_free())

	if get_node_or_null("/root/MusicaManager"):
		MusicaManager.play_sfx("incorrecto")

# ─────────────────────────────────────────────────────────────
#  MUNDO COMPLETO (secciones 6–10)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_completas() -> bool:
	for i in range(6, 11):
		if not guardado_node.seccion_completada(i):
			return false
	return true

# ─────────────────────────────────────────────────────────────
#  PANEL DIÁLOGO — fondo naranja del diseñador
# ─────────────────────────────────────────────────────────────
var _panel_bg_npc : Node = null

func _configurar_panel_dialogo() -> void:
	var cr = $UI/PanelDialogo.get_node_or_null("ColorRect")
	if cr:
		cr.visible = false

	var script = load("res://scripts/panel_dialogo_npc.gd")
	var panel_bg := Control.new()
	panel_bg.set_script(script)
	$UI/PanelDialogo.add_child(panel_bg)
	$UI/PanelDialogo.move_child(panel_bg, 0)
	panel_bg.layout_mode = 1
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_bg_npc = panel_bg

	$UI/PanelDialogo/LabelTexto.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	# Permitir que LabelNombre sobresalga hacia la pestañita (por encima del panel)
	$UI/PanelDialogo.clip_contents = false
	var ln_cfg = $UI/PanelDialogo/LabelNombre
	ln_cfg.layout_mode = 1   # modo anclado para poder usar anchors/offsets
	ln_cfg.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	ln_cfg.add_theme_font_size_override("font_size", 15)

# ═══════════════════════════════════════════════════════════════
#  DIÁLOGO ESTILO RPG — construye el overlay una sola vez
# ═══════════════════════════════════════════════════════════════
func _crear_rpg_layer() -> void:
	_rpg_layer = CanvasLayer.new()
	_rpg_layer.layer   = 90   # por encima de todo
	_rpg_layer.visible = false
	add_child(_rpg_layer)

	# ── Fondo: leve atenuado negro para que los retratos destaquen ──
	_rpg_bg = ColorRect.new()
	_rpg_bg.color        = Color(0.0, 0.0, 0.0, 0.0)
	_rpg_bg.layout_mode  = 0
	_rpg_bg.position     = Vector2.ZERO
	_rpg_bg.size         = Vector2(1280.0, 720.0)
	_rpg_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_bg)

	# ── Retrato de Mati (izquierda, volteado hacia la derecha) ──
	_rpg_mati_ret = TextureRect.new()
	_rpg_mati_ret.layout_mode  = 0
	_rpg_mati_ret.size         = Vector2(460.0, 540.0)
	_rpg_mati_ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rpg_mati_ret.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	# scale.x = -1 → voltea el retrato; position.x pasa a ser el BORDE DERECHO visual
	_rpg_mati_ret.scale        = Vector2(-1.0, 1.0)
	_rpg_layer.add_child(_rpg_mati_ret)

	# ── Retrato del NPC (derecha) ─────────────────────────────
	_rpg_npc_ret = TextureRect.new()
	_rpg_npc_ret.layout_mode  = 0
	_rpg_npc_ret.size         = Vector2(460.0, 540.0)
	_rpg_npc_ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rpg_npc_ret.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_rpg_layer.add_child(_rpg_npc_ret)

	# ── Panel de diálogo — gradiente naranja→amarillo ─────────
	_rpg_dlg_box = Control.new()
	_rpg_dlg_box.set_script(load("res://scripts/panel_dialogo_npc.gd"))
	_rpg_dlg_box.layout_mode  = 0
	_rpg_dlg_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_dlg_box)

	# ── Label nombre (sobre la pestaña) ──────────────────────
	_rpg_lbl_nom = Label.new()
	_rpg_lbl_nom.layout_mode = 0
	_rpg_lbl_nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rpg_lbl_nom.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_rpg_lbl_nom.add_theme_font_size_override("font_size", 15)
	_rpg_lbl_nom.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	_rpg_lbl_nom.add_theme_color_override("font_shadow_color", Color(1.0, 0.9, 0.5, 0.5))
	_rpg_lbl_nom.add_theme_constant_override("shadow_offset_x", 1)
	_rpg_lbl_nom.add_theme_constant_override("shadow_offset_y", 1)
	_rpg_lbl_nom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_lbl_nom)

	# ── Label texto (typewriter) ──────────────────────────────
	_rpg_lbl_txt = Label.new()
	_rpg_lbl_txt.layout_mode   = 0
	_rpg_lbl_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rpg_lbl_txt.add_theme_font_size_override("font_size", 20)
	_rpg_lbl_txt.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	_rpg_lbl_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_lbl_txt)

	# ── Botón "¡Jugar!" ───────────────────────────────────────
	_rpg_btn_ayd = TextureButton.new()
	_rpg_btn_ayd.layout_mode = 0
	# CRÍTICO: ignore_texture_size=true permite que el botón respete
	# el size asignado, en vez de renderizarse al tamaño real de la textura.
	_rpg_btn_ayd.ignore_texture_size = true
	_rpg_btn_ayd.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var tex_btn : Texture2D = load("res://assets/ui/boton_jugar.png")
	if tex_btn:
		_rpg_btn_ayd.texture_normal = tex_btn
	_rpg_btn_ayd.scale   = Vector2(1.0, 1.0)
	_rpg_btn_ayd.visible = false
	_rpg_btn_ayd.pressed.connect(_iniciar_desafio)
	_rpg_layer.add_child(_rpg_btn_ayd)

	# ── Hint "toca para cerrar" ───────────────────────────────
	_rpg_lbl_cls = Label.new()
	_rpg_lbl_cls.layout_mode = 0
	_rpg_lbl_cls.text = "▸ Toca para cerrar"
	_rpg_lbl_cls.add_theme_font_size_override("font_size", 15)
	_rpg_lbl_cls.add_theme_color_override("font_color", Color(0.42, 0.16, 0.01, 0.85))
	_rpg_lbl_cls.visible = false
	_rpg_layer.add_child(_rpg_lbl_cls)

	# ── Estrellas decorativas (6 labels ★) ──────────────────
	var star_sizes := [32, 28, 36, 24, 30, 26]
	for i in range(6):
		var s := Label.new()
		s.text = "★"
		s.layout_mode  = 0
		s.add_theme_font_size_override("font_size", star_sizes[i])
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.visible      = false
		_rpg_layer.add_child(s)
		_rpg_estrellas.append(s)

# ─────────────────────────────────────────────────────────────
#  DIÁLOGO DEL NPC
# ─────────────────────────────────────────────────────────────
func _mostrar_dialogo_npc(idx: int) -> void:
	npc_activo = idx
	var npc_data   = NPCS_DATA[idx]
	var completada = guardado_node.seccion_completada(npc_data["seccion"])

	dialogo_activo   = true
	texto_indice     = 0
	texto_completo   = false
	texto_npc_actual = npc_data["dialogo_hecho"] if completada else npc_data["dialogo"]

	$BtnInteractuar.visible = false
	if label_npc_nombre: label_npc_nombre.visible = false

	# ── Abrir overlay RPG ─────────────────────────────────────
	if _rpg_layer == null:
		return

	# Textura del NPC
	var ruta_npc : String = npc_data.get("textura", "")
	if ruta_npc != "" and ResourceLoader.exists(ruta_npc):
		_rpg_npc_ret.texture = load(ruta_npc)
	else:
		_rpg_npc_ret.texture = null

	# Textura de Mati (skin activa)
	_rpg_mati_ret.texture = _skin_vistas.get("frente", $Mati/Sprite2D.texture)

	# Nombre del NPC
	_rpg_lbl_nom.text = "  " + npc_data["nombre"] + "  "

	# Reset texto y botones
	_rpg_lbl_txt.text    = ""
	_rpg_btn_ayd.visible = false
	_rpg_lbl_cls.visible = false

	# ── VIEWPORT ──────────────────────────────────────────────
	var vp   := get_viewport().get_visible_rect().size
	var vp_w := vp.x   # 1280
	var vp_h := vp.y   # 720

	_rpg_bg.size = vp

	# ══════════════════════════════════════════════════════════
	# RETRATOS — grandes, pegados a los bordes de pantalla.
	# 29% de ancho = 371 px. 72% de alto = 518 px.
	# STRETCH_KEEP_ASPECT_COVERED → el personaje LLENA el rect
	# ══════════════════════════════════════════════════════════
	var port_w := vp_w * 0.29       # 371.2 px
	var port_h := vp_h * 0.72       # 518.4 px
	var port_y := vp_h - port_h     # 201.6 px (pegado al fondo)

	# Mati un poco más pequeño que el NPC (80%)
	var mati_w := port_w * 0.80    # ≈ 297 px
	var mati_h := port_h * 0.80    # ≈ 414 px
	var mati_y := vp_h - mati_h    # ≈ 306 px

	_rpg_mati_ret.size = Vector2(mati_w, mati_h)
	_rpg_npc_ret.size  = Vector2(port_w, port_h)

	# Mati (scale.x = -1): position.x = BORDE DERECHO visual.
	_rpg_mati_dest_x       = mati_w
	_rpg_mati_ret.position = Vector2(-mati_w, mati_y)   # off-screen izq

	# NPC: position.x = BORDE IZQUIERDO visual.
	_rpg_npc_dest_x       = vp_w - port_w
	_rpg_npc_ret.position = Vector2(vp_w + port_w * 0.5, port_y)  # off-screen der

	# ══════════════════════════════════════════════════════════
	# PANEL DE DIÁLOGO — entre los dos retratos.
	# El botón JUGAR queda DENTRO de la caja, al fondo.
	# ══════════════════════════════════════════════════════════
	const BTN_TEX_W : float = 420.0
	const BTN_TEX_H : float = 130.0
	var btn_h : float = 46.0
	var btn_w : float = BTN_TEX_W * (btn_h / BTN_TEX_H)   # ≈ 149 px
	_rpg_btn_ayd.scale = Vector2(1.0, 1.0)
	_rpg_btn_ayd.size  = Vector2(btn_w, btn_h)

	var dlg_gap : float = 10.0
	var dlg_x   : float = mati_w + dlg_gap
	var dlg_w   : float = (vp_w - port_w) - mati_w - dlg_gap * 2.0
	var dlg_h   : float = vp_h * 0.35
	var dlg_y   : float = vp_h - dlg_h - 16.0

	_rpg_dlg_box.size     = Vector2(dlg_w, dlg_h)
	_rpg_dlg_box.position = Vector2(dlg_x, dlg_y)
	if _rpg_dlg_box.has_method("setup"):
		_rpg_dlg_box.call("setup", false)   # pestaña a la izquierda

	# ── Label nombre — sobre la pestaña ───────────────────────
	_rpg_lbl_nom.position = Vector2(dlg_x + 20.0, dlg_y - 32.0)
	_rpg_lbl_nom.size     = Vector2(118.0, 38.0)

	# ── Texto — llena la caja dejando espacio para el botón ───
	var txt_pad_top  : float = 10.0
	var btn_reserved : float = btn_h + 18.0
	_rpg_lbl_txt.position = Vector2(dlg_x + 12.0, dlg_y + txt_pad_top)
	_rpg_lbl_txt.size     = Vector2(dlg_w - 24.0, dlg_h - txt_pad_top - btn_reserved)

	# ── Botón JUGAR — centrado, al fondo de la caja ───────────
	_rpg_btn_ayd.position = Vector2(
		dlg_x + (dlg_w - btn_w) * 0.5,
		dlg_y + dlg_h - btn_h - 12.0
	)

	# ── Hint "toca para cerrar" ───────────────────────────────
	_rpg_lbl_cls.position = Vector2(dlg_x + dlg_w - 196.0, dlg_y + dlg_h - 22.0)

	# ── ESTRELLAS alrededor del NPC ───────────────────────────
	var sx_base : float = _rpg_npc_dest_x
	var sy_base : float = port_y
	var star_pos := [
		Vector2(sx_base + 60.0,  sy_base - 30.0),
		Vector2(sx_base + 200.0, sy_base - 15.0),
		Vector2(sx_base + 120.0, sy_base - 65.0),
		Vector2(sx_base + 20.0,  sy_base + 50.0),
		Vector2(sx_base + 250.0, sy_base + 60.0),
		Vector2(sx_base + 150.0, sy_base - 90.0),
	]
	for i in range(_rpg_estrellas.size()):
		var s : Label = _rpg_estrellas[i]
		s.position = star_pos[i]
		s.scale    = Vector2(0.05, 0.05)
		s.modulate = Color(1.0, 1.0, 1.0, 0.0)
		s.visible  = true

	_rpg_layer.visible = true

	# ── Animaciones de entrada ────────────────────────────────
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	# Retratos slide-in desde los bordes
	tw.tween_property(_rpg_mati_ret, "position:x", _rpg_mati_dest_x, 0.42)
	tw.tween_property(_rpg_npc_ret,  "position:x", _rpg_npc_dest_x,  0.42).set_delay(0.06)
	# Fondo fade-in leve
	var c_final := Color(0.0, 0.0, 0.0, 0.38)
	_rpg_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	tw.tween_property(_rpg_bg, "color", c_final, 0.30)
	# Estrellas pop-in con delay escalonado
	for i in range(_rpg_estrellas.size()):
		var s : Label = _rpg_estrellas[i]
		var stw := create_tween()
		stw.set_ease(Tween.EASE_OUT)
		stw.set_trans(Tween.TRANS_BACK)
		stw.tween_property(s, "scale",      Vector2(1.0, 1.0), 0.32).set_delay(0.28 + i * 0.06)
		stw.tween_property(s, "modulate:a", 1.0,               0.22).set_delay(0.28 + i * 0.06)

func _process(delta: float) -> void:
	# ── Bobbing de NPCs (mundo vivo) ────────────────────────────
	if animacion_lista and not $UI/PanelPausa.visible:
		tiempo_mundo += delta
		for i in range(npc_nodes.size()):
			var bob := sin(tiempo_mundo * 1.85 + float(i) * 1.25) * 5.5
			npc_nodes[i].position = npc_base_pos[i] + Vector2(0.0, bob)
			pass   # NPCs usan z_index por orden de árbol

	# ── Texto del diálogo (typewriter) ──────────────────────────
	if not dialogo_activo or texto_completo:
		return
	texto_timer += delta
	if texto_timer >= VELOCIDAD_TEXTO:
		texto_timer = 0.0
		if texto_indice < texto_npc_actual.length():
			texto_indice += 1
			if _rpg_lbl_txt: _rpg_lbl_txt.text = texto_npc_actual.substr(0, texto_indice)
		else:
			texto_completo = true
			if npc_activo >= 0:
				var sec_completada = guardado_node.seccion_completada(NPCS_DATA[npc_activo]["seccion"])
				if _rpg_btn_ayd: _rpg_btn_ayd.visible = not sec_completada
			# Mostrar "toca para cerrar" si no hay botón de acción pendiente
			var btn_visible : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
			if not btn_visible:
				if _rpg_lbl_cls: _rpg_lbl_cls.visible = true

func _cerrar_dialogo() -> void:
	dialogo_activo = false
	if _rpg_layer != null and _rpg_layer.visible:
		# Ocultar estrellas inmediatamente
		for s in _rpg_estrellas: s.visible = false
		# Slide-out de retratos + fade del fondo
		var vp := get_viewport().get_visible_rect().size
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_ease(Tween.EASE_IN)
		tw.set_trans(Tween.TRANS_QUAD)
		# Mati (flipped, scale.x=-1): para salir por la izquierda → position.x < 0
		tw.tween_property(_rpg_mati_ret, "position:x", -50.0, 0.25)
		tw.tween_property(_rpg_npc_ret,  "position:x", vp.x + 50.0, 0.25)
		tw.tween_property(_rpg_bg, "color", Color(0.0, 0.0, 0.0, 0.0), 0.25)
		# Al terminar → ocultar capa
		tw.chain().tween_callback(func(): _rpg_layer.visible = false)
	else:
		$UI/PanelDialogo.visible = false

# ─────────────────────────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not animacion_lista:
		return

	if dialogo_activo and event is InputEventMouseButton and event.pressed:
		if not texto_completo:
			# Primer clic: mostrar todo el texto de golpe
			texto_indice = texto_npc_actual.length()
			if _rpg_lbl_txt: _rpg_lbl_txt.text = texto_npc_actual
			texto_completo = true
			if npc_activo >= 0:
				var sec_completada = guardado_node.seccion_completada(NPCS_DATA[npc_activo]["seccion"])
				if _rpg_btn_ayd: _rpg_btn_ayd.visible = not sec_completada
			var btn_v2 : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
			if not btn_v2:
				if _rpg_lbl_cls: _rpg_lbl_cls.visible = true
		else:
			# Segundo clic: cerrar si no hay acción pendiente
			var btn_v3 : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
			if not btn_v3:
				_cerrar_dialogo()
		return

	if event is InputEventKey:
		var pressed = event.pressed
		match event.keycode:
			KEY_LEFT,  KEY_A: dir_x = -1.0 if pressed else 0.0
			KEY_RIGHT, KEY_D: dir_x =  1.0 if pressed else 0.0
			KEY_UP,    KEY_W: dir_y = -1.0 if pressed else 0.0
			KEY_DOWN,  KEY_S: dir_y =  1.0 if pressed else 0.0
			KEY_SPACE:
				if pressed and npc_cercano >= 0 and not dialogo_activo:
					_mostrar_dialogo_npc(npc_cercano)
			KEY_ENTER, KEY_KP_ENTER:
				if pressed and dialogo_activo:
					if not texto_completo:
						texto_indice = texto_npc_actual.length()
						if _rpg_lbl_txt: _rpg_lbl_txt.text = texto_npc_actual
						texto_completo = true
						if npc_activo >= 0:
							var sc = guardado_node.seccion_completada(NPCS_DATA[npc_activo]["seccion"])
							if _rpg_btn_ayd: _rpg_btn_ayd.visible = not sc
						var btn_ve : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
						if not btn_ve:
							if _rpg_lbl_cls: _rpg_lbl_cls.visible = true
					else:
						var btn_ve2 : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
						if not btn_ve2: _cerrar_dialogo()
			KEY_ESCAPE:
				if pressed:
					if dialogo_activo:
						_cerrar_dialogo()
					else:
						_toggle_pausa()

# ─────────────────────────────────────────────────────────────
#  BOTÓN INTERACTUAR (táctil)
# ─────────────────────────────────────────────────────────────
func _on_btn_interactuar() -> void:
	if npc_cercano >= 0 and not dialogo_activo:
		_mostrar_dialogo_npc(npc_cercano)

# ─────────────────────────────────────────────────────────────
#  INICIAR DESAFÍO MATEMÁTICO DEL NPC
# ─────────────────────────────────────────────────────────────
func _iniciar_desafio() -> void:
	if npc_activo < 0:
		return
	var seccion_id = NPCS_DATA[npc_activo]["seccion"]
	_cerrar_dialogo()

	var datos = guardado_node.cargar()
	datos["seccion_actual"] = seccion_id
	var archivo = FileAccess.open(guardado_node._ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

	if NPCS_DATA[npc_activo].get("id", "") == "robot":
		# Jefe robot → sistema de combate
		var combate_script = load("res://scripts/combate_jefe.gd")
		combate_script.guardar_config({
			"jefe_nombre":    "ROBO-X",
			"jefe_textura":   "res://assets/npcs/robot_villano.PNG",
			"jefe_vida_max":  8,
			"seccion":        20,
			"tipo_op":        "mixto",
			"nivel_op":       2,
			"total_preguntas": 8,
			"monedas":        10,
			"escena_origen":  "res://scenes/Mundo2Explorar.tscn"
		})
		TransitionManager.cambiar_escena("res://scenes/CombateJefe.tscn")
	else:
		TransitionManager.cambiar_escena("res://scenes/Mundo2Operaciones.tscn")

# ─────────────────────────────────────────────────────────────
#  MOVIMIENTO DE MATI
# ─────────────────────────────────────────────────────────────
func _physics_process(_delta: float) -> void:
	if not animacion_lista:
		return
	if $UI/PanelPausa.visible or dialogo_activo:
		return

	var mati = $Mati
	mati.velocity.x = dir_x * VELOCIDAD
	mati.velocity.y = dir_y * VELOCIDAD
	mati.move_and_slide()

	# ── Bloqueo CIRCULAR de nubes (solo empuja posición, sin rebote) ──
	if nubes_nodo != null:
		var vis_x2 : float = mati.global_position.x
		var vis_y2 : float = mati.global_position.y
		for n in nubes_nodo.nubes:
			var cnx  : float = float(n["x"])
			var cny  : float = float(n["y"])
			var cnr  : float = float(n["r"]) * 1.6
			var diff := Vector2(vis_x2 - cnx, vis_y2 - cny)
			var dist := diff.length()
			if dist < cnr and dist > 0.5:
				var push := diff.normalized()
				mati.global_position.x = cnx + push.x * cnr
				mati.global_position.y = cny + push.y * cnr

	# ── Repulsión suave de NPCs (Mati no puede caminar encima de ellos) ──
	const NPC_RADIO : float = 110.0
	for i in range(npc_nodes.size()):
		if not npc_nodes[i].visible:
			continue
		var npc_pos := NPCS_DATA[i]["pos"] as Vector2
		var diff : Vector2 = mati.global_position - npc_pos
		var dist := diff.length()
		if dist < NPC_RADIO and dist > 0.5:
			mati.global_position = npc_pos + diff.normalized() * NPC_RADIO

	mati.global_position.x = clamp(mati.global_position.x, LIMITE_IZQ, LIMITE_DER)
	mati.global_position.y = clamp(mati.global_position.y, LIMITE_ARR, LIMITE_ABA)

	# ── Vista direccional de Mati ─────────────────────────────────
	var nueva_dir  : String = _dir_actual
	var nuevo_flip : bool   = _flip_perfil
	if dir_x != 0:
		nueva_dir  = "perfil"
		nuevo_flip = (dir_x > 0)
	elif dir_y < 0:
		nueva_dir = "espalda"
	elif dir_y > 0:
		nueva_dir = "frente"
	if nueva_dir != _dir_actual or nuevo_flip != _flip_perfil:
		_dir_actual  = nueva_dir
		_flip_perfil = nuevo_flip
		_actualizar_textura_mati()

	_verificar_proximidad_npcs()

# ─────────────────────────────────────────────────────────────
#  DETECCIÓN DE PROXIMIDAD A LOS NPCs
# ─────────────────────────────────────────────────────────────
func _verificar_proximidad_npcs() -> void:
	if dialogo_activo:
		$BtnInteractuar.visible = false
		if label_npc_nombre:
			label_npc_nombre.visible = false
		npc_cercano_prev = -1
		btn_era_visible  = false
		return

	npc_cercano = -1
	var dist_min : float = DIST_INTERACCION

	for i in range(npc_nodes.size()):
		if not npc_nodes[i].visible:
			continue   # NPCs invisibles no interactúan
		var dist = $Mati.global_position.distance_to(npc_nodes[i].global_position)
		if dist < dist_min:
			dist_min    = dist
			npc_cercano = i

	if npc_cercano >= 0:
		# ── Pop squash-and-stretch al acercarse por primera vez ─
		if npc_cercano != npc_cercano_prev:
			_animar_npc_pop(npc_cercano)
			npc_cercano_prev = npc_cercano

		# Mover botón ! al lado derecho del NPC
		var npc_pos : Vector2 = npc_nodes[npc_cercano].global_position
		$BtnInteractuar.position = npc_pos + Vector2(80, -145)

		# ── Botón aparece con animación de escala ───────────────
		if not btn_era_visible:
			$BtnInteractuar.scale = btn_escala_orig * 0.1
			$BtnInteractuar.visible = true
			var tw := create_tween()
			tw.set_ease(Tween.EASE_OUT)
			tw.set_trans(Tween.TRANS_BACK)
			tw.tween_property($BtnInteractuar, "scale", btn_escala_orig, 0.30)
			btn_era_visible = true

		$BtnInteractuar.visible = true
	else:
		npc_cercano_prev = -1
		btn_era_visible  = false
		if label_npc_nombre:
			label_npc_nombre.visible = false
		$BtnInteractuar.visible = false

# ─────────────────────────────────────────────────────────────
#  ANIMACIÓN SQUASH-AND-STRETCH AL ACERCARSE A UN NPC
# ─────────────────────────────────────────────────────────────
func _animar_npc_pop(idx: int) -> void:
	var npc : Node2D = npc_nodes[idx]
	var e : float = float(NPCS_DATA[idx].get("escala", 1.0))
	npc.scale = Vector2(e, e)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(npc, "scale", Vector2(e * 1.18, e * 0.78), 0.09)
	tw.tween_property(npc, "scale", Vector2(e * 0.85, e * 1.22), 0.13)
	tw.tween_property(npc, "scale", Vector2(e, e), 0.20)

# ─────────────────────────────────────────────────────────────
#  MONEDAS
# ─────────────────────────────────────────────────────────────
func _on_moneda_recolectada(moneda: Node) -> void:
	if not moneda.visible:
		return
	var pos_burst : Vector2 = moneda.global_position
	moneda.visible = false
	monedas_sesion += 1
	_actualizar_label_monedas()
	guardado_node.sumar_monedas(1)
	if get_node_or_null("/root/MusicaManager"):
		MusicaManager.play_sfx("moneda")
	var burst_script = load("res://scripts/moneda_burst.gd")
	if burst_script:
		burst_script.lanzar(self, pos_burst)

func _actualizar_label_monedas() -> void:
	_actualizar_indicador_estrella(monedas_sesion)
	if indicador_wrap_node:
		var tw := create_tween()
		tw.set_ease(Tween.EASE_OUT)
		tw.set_trans(Tween.TRANS_BACK)
		tw.tween_property(indicador_wrap_node, "scale", Vector2(1.4, 1.4), 0.10)
		tw.tween_property(indicador_wrap_node, "scale", Vector2(1.0, 1.0), 0.15)

func _crear_indicador_estrella(parent: Node, pos: Vector2) -> void:
	indicador_wrap_node = Control.new()
	parent.add_child(indicador_wrap_node)
	indicador_wrap_node.layout_mode   = 0
	indicador_wrap_node.position      = pos
	indicador_wrap_node.size          = Vector2(90.0, 90.0)
	indicador_wrap_node.clip_contents = true
	indicador_estrella = TextureRect.new()
	indicador_wrap_node.add_child(indicador_estrella)
	indicador_estrella.layout_mode  = 0
	indicador_estrella.position     = Vector2(0, 0)
	indicador_estrella.size         = Vector2(90.0, 90.0)
	indicador_estrella.stretch_mode = TextureRect.STRETCH_SCALE
	indicador_estrella.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	indicador_label0 = Label.new()
	indicador_wrap_node.add_child(indicador_label0)
	indicador_label0.layout_mode          = 0
	indicador_label0.position             = Vector2(0, 0)
	indicador_label0.size                 = Vector2(90.0, 90.0)
	indicador_label0.text                 = "★ 0"
	indicador_label0.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicador_label0.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	indicador_label0.add_theme_font_size_override("font_size", 24)
	indicador_label0.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	indicador_label0.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	indicador_label0.add_theme_constant_override("shadow_offset_x", 2)
	indicador_label0.add_theme_constant_override("shadow_offset_y", 2)
	indicador_label0.visible = false

func _actualizar_indicador_estrella(n: int) -> void:
	if indicador_estrella == null:
		return
	indicador_wrap_node.visible = true
	if n <= 0:
		indicador_estrella.visible = false
		if indicador_label0:
			indicador_label0.visible = true
		return
	if indicador_label0:
		indicador_label0.visible = false
	indicador_estrella.visible = true
	var c    : int    = clampi(n, 1, 100)
	var ruta : String = "res://assets/ui/indicador_estrellas/%d.png" % c
	if ResourceLoader.exists(ruta):
		indicador_estrella.texture = load(ruta)
	else:
		indicador_wrap_node.visible = false

# ─────────────────────────────────────────────────────────────
#  PAUSA / IR AL MAPA
# ─────────────────────────────────────────────────────────────
func _aplicar_skin(skin_id: String) -> void:
	if not has_node("Mati/Sprite2D"): return
	var vistas = SKINS_VISTAS.get(skin_id, SKINS_VISTAS["default"])
	_skin_vistas = {}
	for key in vistas:
		var ruta : String = vistas[key]
		if ResourceLoader.exists(ruta):
			_skin_vistas[key] = load(ruta)
	_actualizar_textura_mati()

func _actualizar_textura_mati() -> void:
	if not has_node("Mati/Sprite2D"): return
	var sprite := $Mati/Sprite2D
	var tex : Texture2D = _skin_vistas.get(_dir_actual, _skin_vistas.get("frente"))
	if tex == null: return
	const TARGET_W : float = 186.8
	const TARGET_H : float = 201.4
	sprite.texture = tex
	sprite.scale   = Vector2(
		-TARGET_W / float(tex.get_width()),
		 TARGET_H / float(tex.get_height())
	)
	sprite.flip_h = (_dir_actual == "perfil" and _flip_perfil)

func _toggle_pausa() -> void:
	var pausado = not $UI/PanelPausa.visible
	$UI/PanelPausa.visible = pausado
	get_tree().paused = pausado

func _on_volumen_presionado() -> void:
	var muteado = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, not muteado)
	_actualizar_icono_volumen()

func _actualizar_icono_volumen() -> void:
	if not has_node("UI/PanelPausa/BtnVolumen"): return
	if AudioServer.is_bus_mute(0):
		$UI/PanelPausa/BtnVolumen.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		$UI/PanelPausa/BtnVolumen.modulate = Color(1, 1, 1, 1)

func _ir_al_mapa() -> void:
	get_tree().paused = false
	TransitionManager.cambiar_escena("res://scenes/Mapa.tscn")

# ─────────────────────────────────────────────────────────────
#  TILING DEL FONDO
#  Clona el Sprite2D $Fondo para cubrir el mundo extendido.
# ─────────────────────────────────────────────────────────────
func _extender_fondo() -> void:
	if not $Fondo.texture:
		return
	var tw  : float     = float($Fondo.texture.get_width()) * absf($Fondo.scale.x)
	if tw < 1.0:
		return
	var cx  : float     = $Fondo.position.x
	var cy  : float     = $Fondo.position.y
	var sc  : Vector2   = $Fondo.scale
	var tex : Texture2D = $Fondo.texture

	var n_izq : int = ceili((cx + tw * 0.5 - LIMITE_IZQ) / tw)
	var n_der : int = ceili((LIMITE_DER - cx + tw * 0.5) / tw)

	for i in range(1, n_izq + 1):
		var t := Sprite2D.new()
		t.texture  = tex
		t.scale    = sc
		t.position = Vector2(cx - tw * float(i), cy)
		t.z_index  = -2
		add_child(t)

	for i in range(1, n_der + 1):
		var t := Sprite2D.new()
		t.texture  = tex
		t.scale    = sc
		t.position = Vector2(cx + tw * float(i), cy)
		t.z_index  = -2
		add_child(t)

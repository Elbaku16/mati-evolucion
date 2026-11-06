extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MUNDO 3 — PLANETA DE HONGOS
#  El jugador recorre el mundo y habla con 5 NPCs.
#  Cada NPC tiene su historia y su desafío matemático propio.
#  No existe pantalla de selección de secciones.
# ═══════════════════════════════════════════════════════════════

const VELOCIDAD        : float = 280.0
const DIST_INTERACCION : float = 280.0

const LIMITE_IZQ  : float = -2030.0
const LIMITE_DER  : float =  2680.0
const LIMITE_ARR  : float =   580.0
const LIMITE_ABA  : float =  1500.0

const RUTA_SAVE : String = "user://mati_save.json"

# ─────────────────────────────────────────────────────────────
#  DATOS DE LOS 5 NPCs DEL MUNDO 3
#  seccion: ID del desafío (11–15), mismo que el sistema de guardado
# ─────────────────────────────────────────────────────────────
const NPCS_DATA : Array = [
	{
		"id":            "fungi",
		"nombre":        "Fungi",
		"seccion":       11,
		"pos":           Vector2(-1600, 950),
		"textura":       "res://assets/npcs/Alien hongo morado.PNG",
		"dialogo":       "¡Oye, oye! Soy Fungi.\nMis esporas mágicas se multiplican\nde a tres cada vez.\n¿Conoces la tabla del 3?",
		"dialogo_hecho": "¡Mis esporas están a salvo!\nGracias Mati, eres el más inteligente\ndel Planeta Hongos."
	},
	{
		"id":            "brote",
		"nombre":        "Brote",
		"seccion":       12,
		"pos":           Vector2(-700, 1050),
		"textura":       "res://assets/npcs/Alien hongo verde.PNG",
		"dialogo":       "Hola, soy Brote el hongo verde.\nCuando llueve aquí los hongos\ncrecen de a cuatro...\n¡Enséñame la tabla del 4!",
		"dialogo_hecho": "¡Ahora sé cuántos hongos\ncrecerán la próxima lluvia!\nGracias por enseñarme, Mati."
	},
	{
		"id":            "blanco",
		"nombre":        "Blanco",
		"seccion":       15,
		"pos":           Vector2(250, 900),
		"textura":       "res://assets/npcs/Alien hongo blanco.PNG",
		"dialogo":       "Hola... soy Blanco.\nSiempre estoy triste porque\nno recuerdo la tabla del 6...\n¿Me puedes ayudar a aprenderla?",
		"dialogo_hecho": "Ya no estoy triste.\nAhora recuerdo perfectamente\nla tabla del 6. ¡Gracias Mati!"
	},
	{
		"id":            "orbis",
		"nombre":        "Orbis",
		"seccion":       13,
		"pos":           Vector2(1000, 1000),
		"textura":       "res://assets/npcs/Astronauta negro.PNG",
		"dialogo":       "Soy Orbis, astronauta del cosmos.\nViajé galaxias estudiando el 5.\nLa tabla del 5 es mi secreto.\n¿Puedes rivalizar conmigo?",
		"dialogo_hecho": "¡Extraordinario, Mati!\nDominas la tabla del 5\ncomo un verdadero astronauta."
	},
	{
		"id":            "turbo",
		"nombre":        "Turbo",
		"seccion":       16,
		"pos":           Vector2(1700, 920),
		"textura":       "res://assets/npcs/Niño azul.PNG",
		"dialogo":       "¡Hiya! Soy Turbo, el más veloz\ndel Planeta Hongos.\nCorro de 7 en 7 pasos.\n¡Pon a prueba la tabla del 7!",
		"dialogo_hecho": "¡Velocidad mental increíble, Mati!\nYa puedo calcular mis carreras\ncon la tabla del 7. ¡Genial!"
	},
	{
		"id":            "aliencita",
		"nombre":        "Aliencita",
		"seccion":       14,
		"pos":           Vector2(2200, 1000),
		"textura":       "res://assets/npcs/aliencita.PNG",
		"dialogo":       "¡Hola hola! Soy Aliencita.\nSoy pequeña pero muy inteligente.\nMezclé las tablas del 3 al 7...\n¡Ayúdame a resolverlas todas!",
		"dialogo_hecho": "¡Eres increíble, Mati!\nNadie había resuelto tan rápido\nmis multiplicaciones mezcladas."
	},
	{
		"id":            "jefe_hongo",
		"nombre":        "El Gran Mago",
		"seccion":       17,
		"pos":           Vector2(2500, 980),     # Extremo derecho — el jefe final
		"escala":        1.5,                    # jefe final mas grande e imponente
		"textura":       "res://assets/npcs/Jefe hongo.PNG",
		"dialogo":       "¡Ja ja ja! Soy el Gran Mago\nde los Hongos Cósmicos.\nNadie ha pasado por aqui\nsin resolver mis multiplicaciones.\n¡Enfrentate a TODAS las tablas\nsi te atreves!",
		"dialogo_hecho": "¡Increible, Mati!\nNunca nadie habia derrotado\nmis multiplicaciones tan bien.\n¡Eres el campeon del Planeta Hongos!"
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
var animacion_lista   : bool  = true
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

	# Identidad del planeta

	if get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").musica_explorar_mundo(3)

	var _efectos_e = load("res://scripts/efectos_ui.gd")
	if _efectos_e:
		_efectos_e.flash_blanco(get_tree().root)

	monedas_sesion = int(datos.get("monedas", 0))
	$UI/LabelMonedas.visible = false
	_crear_indicador_estrella($UI, Vector2(10.0, 8.0))
	_actualizar_label_monedas()

	mision_completada = _todas_secciones_completas()
	btn_escala_orig = $BtnInteractuar.scale
	$BtnInteractuar.visible = false
	$BtnInteractuar.z_index = 500

	# Aplicar skin del jugador (con escala normalizada)
	var skin_id = datos.get("skin_activa", "default")
	_aplicar_skin(skin_id)

	# Crear NPCs programáticamente
	_crear_npcs()
	_actualizar_visual_npcs()
	_intentar_revelar_jefe()

	# Actualizar portal
	_actualizar_portal()

	# Hongos flotantes en el cielo
	$Fondo.z_index = -2
	nubes_nodo = Node2D.new()
	nubes_nodo.set_script(load("res://scripts/efectos_nubes_hongos.gd"))
	add_child(nubes_nodo)

	# Esporas ambientales
	var efectos_hongos := Node2D.new()
	efectos_hongos.set_script(load("res://scripts/efectos_ambiente_hongos.gd"))
	efectos_hongos.z_index = -1
	add_child(efectos_hongos)

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

	# Panel de diálogo — oculto; usamos el sistema RPG
	$UI/PanelDialogo.visible = false
	$UI/PanelDialogo/BtnAyudar.visible = false
	$UI/PanelDialogo/BtnAyudar.pressed.connect(_iniciar_desafio)
	_configurar_panel_dialogo()
	_crear_rpg_layer()

	# Monedas dispersas
	for moneda in get_tree().get_nodes_in_group("moneda"):
		moneda.body_entered.connect(_on_moneda_recolectada.bind(moneda))

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
		add_child(npc)
		var tex : Texture2D = null
		var es_jefe : bool = (npc_data.get("id", "") == "jefe_hongo")
		if not es_jefe and ResourceLoader.exists(npc_data["textura"]):
			tex = load(npc_data["textura"])
		npc.setup(tex)
		var completado = guardado_node.seccion_completada(npc_data["seccion"])
		npc.marcar_completado(completado)
		npc_nodes.append(npc)
		npc_base_pos.append(npc_data["pos"])

		# El Gran Mago (jefe final) usa la animación de su hechizo como única figura
		if es_jefe:
			_crear_hechizo_jefe(npc)
			_animar_jefe(npc)
			npc.visible = false   # permanece oculto hasta su aparición épica (ver _intentar_revelar_jefe)

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
#  HECHIZO ANIMADO DEL JEFE FINAL (El Gran Mago)
# ─────────────────────────────────────────────────────────────
func _crear_hechizo_jefe(npc: Node2D) -> void:
	var frames : Array = []
	for i in range(6):
		frames.append("res://assets/animaciones/jefe_hongo_hechizo_%d.png" % i)

	var efecto = load("res://scripts/efecto_animado.gd").new()
	npc.add_child(efecto)
	efecto.iniciar(frames, 6.0, true)
	efecto.position = Vector2(0, -120)   # centrado, pies a nivel del suelo (igual que los demás NPCs)
	efecto.scale    = Vector2(0.46875, 0.46875)
	efecto.z_index  = -1   # detrás del badge ✓ que dibuja npc_personaje.gd

# ─────────────────────────────────────────────────────────────
#  ANIMACIÓN DE "RESPIRACIÓN" IMPONENTE DEL JEFE FINAL
# ─────────────────────────────────────────────────────────────
func _animar_jefe(npc: Node2D) -> void:
	var escala_base = npc.scale
	npc.scale = escala_base * 1.05
	var tw = create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(npc, "scale", escala_base * 1.12, 1.2)
	tw.tween_property(npc, "scale", escala_base * 1.05, 1.2)

# ─────────────────────────────────────────────────────────────
#  BLOQUEO DEL JEFE FINAL: hay que ayudar a todos los demás antes
# ─────────────────────────────────────────────────────────────
func _jefe_bloqueado() -> bool:
	for i in range(11, 17):
		if not guardado_node.seccion_completada(i):
			return true
	return false

func _btn_ayudar_visible(sec_completada: bool) -> bool:
	if sec_completada:
		return false
	if npc_activo >= 0 and NPCS_DATA[npc_activo].get("id", "") == "jefe_hongo" and _jefe_bloqueado():
		return false
	return true

# ─────────────────────────────────────────────────────────────
#  REVELACIÓN DEL JEFE FINAL
#  Permanece invisible mientras está bloqueado. En cuanto el
#  jugador ayuda al último guardián, aparece con una entrada épica.
# ─────────────────────────────────────────────────────────────
func _intentar_revelar_jefe() -> void:
	var idx : int = -1
	for i in range(NPCS_DATA.size()):
		if NPCS_DATA[i].get("id", "") == "jefe_hongo":
			idx = i
			break
	if idx == -1:
		return

	var completada : bool = guardado_node.seccion_completada(NPCS_DATA[idx]["seccion"])
	if completada:
		npc_nodes[idx].visible = true
		return
	if _jefe_bloqueado():
		npc_nodes[idx].visible = false
		return

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(npc_nodes[idx]):
		_animar_aparicion_jefe(npc_nodes[idx])

func _animar_aparicion_jefe(npc: Node2D) -> void:
	npc.visible    = true
	npc.modulate   = Color(1, 1, 1, 0)
	var escala_final : Vector2 = npc.scale
	npc.scale = escala_final * 0.3

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(npc, "modulate:a", 1.0, 0.5)
	tw.tween_property(npc, "scale", escala_final, 0.6)

	_mostrar_banner_jefe()

# ─────────────────────────────────────────────────────────────
#  PRESENTACIÓN ÉPICA AL ENFRENTAR AL JEFE FINAL
# ─────────────────────────────────────────────────────────────
func _mostrar_banner_jefe() -> void:
	var vp := get_viewport().get_visible_rect().size
	var banner := Label.new()
	banner.text = "¡JEFE FINAL!"
	banner.add_theme_font_size_override("font_size", 64)
	banner.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	banner.add_theme_color_override("font_shadow_color", Color(0.4, 0.0, 0.0, 1.0))
	banner.add_theme_constant_override("shadow_offset_x", 4)
	banner.add_theme_constant_override("shadow_offset_y", 4)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	banner.size     = Vector2(vp.x, 100)
	banner.position = Vector2(0, vp.y * 0.5 - 50)
	banner.pivot_offset = banner.size * 0.5
	banner.modulate     = Color(1, 1, 1, 0)
	banner.scale        = Vector2(1.6, 1.6)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index      = 100
	$UI.add_child(banner)

	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(banner, "scale", Vector2(1.0, 1.0), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(banner, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): banner.queue_free())

	# Sacudida de cámara para darle impacto a la entrada del jefe
	var cam := $Mati/Camera2D
	var orig_offset : Vector2 = cam.offset
	var shake_tw := create_tween()
	for i in range(6):
		var off := Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
		shake_tw.tween_property(cam, "offset", orig_offset + off, 0.04)
	shake_tw.tween_property(cam, "offset", orig_offset, 0.04)

# ─────────────────────────────────────────────────────────────
#  PORTAL (encendido cuando todas las secciones están hechas)
# ─────────────────────────────────────────────────────────────
func _actualizar_portal() -> void:
	if has_node("SpritePortal"):
		$SpritePortal.visible = false

# ─────────────────────────────────────────────────────────────
#  MUNDO COMPLETO (secciones 11–15)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_completas() -> bool:
	for i in range(11, 18):
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
	$UI/PanelDialogo.clip_contents = false
	var ln_cfg = $UI/PanelDialogo/LabelNombre
	ln_cfg.layout_mode = 1
	ln_cfg.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	ln_cfg.add_theme_font_size_override("font_size", 15)

# ═══════════════════════════════════════════════════════════════
#  DIÁLOGO ESTILO RPG — construye el overlay una sola vez
# ═══════════════════════════════════════════════════════════════
func _crear_rpg_layer() -> void:
	_rpg_layer = CanvasLayer.new()
	_rpg_layer.layer   = 90
	_rpg_layer.visible = false
	add_child(_rpg_layer)

	_rpg_bg = ColorRect.new()
	_rpg_bg.color        = Color(0.0, 0.0, 0.0, 0.0)
	_rpg_bg.layout_mode  = 0
	_rpg_bg.position     = Vector2.ZERO
	_rpg_bg.size         = Vector2(1280.0, 720.0)
	_rpg_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_bg)

	_rpg_mati_ret = TextureRect.new()
	_rpg_mati_ret.layout_mode  = 0
	_rpg_mati_ret.size         = Vector2(460.0, 540.0)
	_rpg_mati_ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rpg_mati_ret.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_rpg_mati_ret.scale        = Vector2(-1.0, 1.0)
	_rpg_layer.add_child(_rpg_mati_ret)

	_rpg_npc_ret = TextureRect.new()
	_rpg_npc_ret.layout_mode  = 0
	_rpg_npc_ret.size         = Vector2(460.0, 540.0)
	_rpg_npc_ret.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_rpg_npc_ret.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_rpg_layer.add_child(_rpg_npc_ret)

	_rpg_dlg_box = Control.new()
	_rpg_dlg_box.set_script(load("res://scripts/panel_dialogo_npc.gd"))
	_rpg_dlg_box.layout_mode  = 0
	_rpg_dlg_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_dlg_box)

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

	_rpg_lbl_txt = Label.new()
	_rpg_lbl_txt.layout_mode   = 0
	_rpg_lbl_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rpg_lbl_txt.add_theme_font_size_override("font_size", 20)
	_rpg_lbl_txt.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	_rpg_lbl_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_lbl_txt)

	_rpg_btn_ayd = TextureButton.new()
	_rpg_btn_ayd.layout_mode = 0
	_rpg_btn_ayd.ignore_texture_size = true
	_rpg_btn_ayd.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var tex_btn : Texture2D = load("res://assets/ui/boton_jugar.png")
	if tex_btn:
		_rpg_btn_ayd.texture_normal = tex_btn
	_rpg_btn_ayd.scale   = Vector2(1.0, 1.0)
	_rpg_btn_ayd.visible = false
	_rpg_btn_ayd.pressed.connect(_iniciar_desafio)
	_rpg_layer.add_child(_rpg_btn_ayd)

	_rpg_lbl_cls = Label.new()
	_rpg_lbl_cls.layout_mode = 0
	_rpg_lbl_cls.text = "▸ Toca para cerrar"
	_rpg_lbl_cls.add_theme_font_size_override("font_size", 15)
	_rpg_lbl_cls.add_theme_color_override("font_color", Color(0.42, 0.16, 0.01, 0.85))
	_rpg_lbl_cls.visible = false
	_rpg_layer.add_child(_rpg_lbl_cls)

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

	var es_jefe : bool = npc_data.get("id", "") == "jefe_hongo"
	if es_jefe and not completada and _jefe_bloqueado():
		texto_npc_actual = "¡Ja, ja, ja! Aun no estas listo\npara enfrentarme, pequeño Mati.\nPrimero demuestra tu valor:\nayuda a TODOS los habitantes\ndel Planeta Hongos.\n¡Vuelve cuando hayas resuelto\ntodos sus desafios!"
	else:
		texto_npc_actual = npc_data["dialogo_hecho"] if completada else npc_data["dialogo"]

	$BtnInteractuar.visible = false
	if label_npc_nombre: label_npc_nombre.visible = false

	if _rpg_layer == null:
		return

	var ruta_npc : String = npc_data.get("textura", "")
	if ruta_npc != "" and ResourceLoader.exists(ruta_npc):
		_rpg_npc_ret.texture = load(ruta_npc)
	else:
		_rpg_npc_ret.texture = null

	_rpg_mati_ret.texture = _skin_vistas.get("frente", $Mati/Sprite2D.texture)
	_rpg_lbl_nom.text = "  " + npc_data["nombre"] + "  "
	_rpg_lbl_txt.text    = ""
	_rpg_btn_ayd.visible = false
	_rpg_lbl_cls.visible = false

	var vp   := get_viewport().get_visible_rect().size
	var vp_w := vp.x
	var vp_h := vp.y

	_rpg_bg.size = vp

	var port_w := vp_w * 0.29
	var port_h := vp_h * 0.72
	var port_y := vp_h - port_h

	var mati_w := port_w * 0.80
	var mati_h := port_h * 0.80
	var mati_y := vp_h - mati_h

	_rpg_mati_ret.size = Vector2(mati_w, mati_h)
	_rpg_npc_ret.size  = Vector2(port_w, port_h)

	_rpg_mati_dest_x       = mati_w
	_rpg_mati_ret.position = Vector2(-mati_w, mati_y)

	_rpg_npc_dest_x       = vp_w - port_w
	_rpg_npc_ret.position = Vector2(vp_w + port_w * 0.5, port_y)

	const BTN_TEX_W : float = 420.0
	const BTN_TEX_H : float = 130.0
	var btn_h : float = 46.0
	var btn_w : float = BTN_TEX_W * (btn_h / BTN_TEX_H)
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
		_rpg_dlg_box.call("setup", false)

	_rpg_lbl_nom.position = Vector2(dlg_x + 20.0, dlg_y - 32.0)
	_rpg_lbl_nom.size     = Vector2(118.0, 38.0)

	var txt_pad_top  : float = 10.0
	var btn_reserved : float = btn_h + 18.0
	_rpg_lbl_txt.position = Vector2(dlg_x + 12.0, dlg_y + txt_pad_top)
	_rpg_lbl_txt.size     = Vector2(dlg_w - 24.0, dlg_h - txt_pad_top - btn_reserved)

	_rpg_btn_ayd.position = Vector2(
		dlg_x + (dlg_w - btn_w) * 0.5,
		dlg_y + dlg_h - btn_h - 12.0
	)

	_rpg_lbl_cls.position = Vector2(dlg_x + dlg_w - 196.0, dlg_y + dlg_h - 22.0)

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

	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_rpg_mati_ret, "position:x", _rpg_mati_dest_x, 0.42)
	tw.tween_property(_rpg_npc_ret,  "position:x", _rpg_npc_dest_x,  0.42).set_delay(0.06)
	var c_final := Color(0.0, 0.0, 0.0, 0.38)
	_rpg_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	tw.tween_property(_rpg_bg, "color", c_final, 0.30)
	for i in range(_rpg_estrellas.size()):
		var s : Label = _rpg_estrellas[i]
		var stw := create_tween()
		stw.set_ease(Tween.EASE_OUT)
		stw.set_trans(Tween.TRANS_BACK)
		stw.tween_property(s, "scale",      Vector2(1.0, 1.0), 0.32).set_delay(0.28 + i * 0.06)
		stw.tween_property(s, "modulate:a", 1.0,               0.22).set_delay(0.28 + i * 0.06)

	if es_jefe and not completada and not _jefe_bloqueado():
		_mostrar_banner_jefe()

func _process(delta: float) -> void:
	if animacion_lista and not $UI/PanelPausa.visible:
		tiempo_mundo += delta
		for i in range(npc_nodes.size()):
			var bob := sin(tiempo_mundo * 1.85 + float(i) * 1.25) * 5.5
			npc_nodes[i].position = npc_base_pos[i] + Vector2(0.0, bob)

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
				if _rpg_btn_ayd: _rpg_btn_ayd.visible = _btn_ayudar_visible(sec_completada)
			var btn_visible : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
			if not btn_visible:
				if _rpg_lbl_cls: _rpg_lbl_cls.visible = true

func _cerrar_dialogo() -> void:
	dialogo_activo = false
	if _rpg_layer != null and _rpg_layer.visible:
		for s in _rpg_estrellas: s.visible = false
		var vp := get_viewport().get_visible_rect().size
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_ease(Tween.EASE_IN)
		tw.set_trans(Tween.TRANS_QUAD)
		tw.tween_property(_rpg_mati_ret, "position:x", -50.0, 0.25)
		tw.tween_property(_rpg_npc_ret,  "position:x", vp.x + 50.0, 0.25)
		tw.tween_property(_rpg_bg, "color", Color(0.0, 0.0, 0.0, 0.0), 0.25)
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
			texto_indice = texto_npc_actual.length()
			if _rpg_lbl_txt: _rpg_lbl_txt.text = texto_npc_actual
			texto_completo = true
			if npc_activo >= 0:
				var sec_completada = guardado_node.seccion_completada(NPCS_DATA[npc_activo]["seccion"])
				if _rpg_btn_ayd: _rpg_btn_ayd.visible = _btn_ayudar_visible(sec_completada)
			var btn_v2 : bool = _rpg_btn_ayd != null and _rpg_btn_ayd.visible
			if not btn_v2:
				if _rpg_lbl_cls: _rpg_lbl_cls.visible = true
		else:
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
							if _rpg_btn_ayd: _rpg_btn_ayd.visible = _btn_ayudar_visible(sc)
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

	if NPCS_DATA[npc_activo].get("id", "") == "jefe_hongo":
		# Lanzar sistema de combate
		var combate_script = load("res://scripts/combate_jefe.gd")
		combate_script.guardar_config({
			"jefe_nombre":    "Jefe Hongo",
			"jefe_textura":   "res://assets/npcs/Jefe hongo.PNG",
			"jefe_vida_max":  10,
			"seccion":        18,
			"tipo_op":        "mult_mixto",
			"min":            4, "max": 9, "min_factor": 5,
			"total_preguntas": 10,
			"monedas":        12,
			"escena_origen":  "res://scenes/Mundo3Explorar.tscn"
		})
		TransitionManager.cambiar_escena("res://scenes/CombateJefe.tscn", "barrido")
	else:
		TransitionManager.cambiar_escena("res://scenes/Mundo3Operaciones.tscn")

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

	const SPRITE_OX : float = -74.0
	const SPRITE_OY : float = -33.0
	const BLK_HW    : float = 180.0
	const BLK_TOP   : float = 260.0
	const BLK_BOT   : float = 60.0

	var move_dir := Vector2(dir_x, dir_y)

	for _pass in range(2):
		if _pass == 1:
			mati.move_and_slide()

		for i in range(npc_nodes.size()):
			if not npc_nodes[i].visible:
				continue
			var nx  : float = npc_base_pos[i].x
			var ny  : float = npc_base_pos[i].y

			var escala_npc : float = float(NPCS_DATA[i].get("escala", 1.0))
			# La caja de bloqueo se limita a 1.2x aunque el NPC sea visualmente
			# más grande (ej. el jefe final a 1.5x); si no, la caja puede quedar
			# más grande que el espacio libre hasta el límite del mundo y atrapar a Mati.
			var escala_blq : float = min(escala_npc, 1.2)
			var blk_hw  : float = BLK_HW  * escala_blq
			var blk_top : float = BLK_TOP * escala_blq
			var blk_bot : float = BLK_BOT * escala_blq

			var vis_x : float = mati.global_position.x + SPRITE_OX
			var dx    : float = vis_x - nx
			var dy    : float = mati.global_position.y - ny

			if absf(dx) > blk_hw or dy < -blk_top or dy > blk_bot:
				continue

			var por_x : bool
			if move_dir.length_squared() < 0.01:
				por_x = absf(dx) / blk_hw >= absf(dy + (blk_top - blk_bot) * 0.5) / ((blk_top + blk_bot) * 0.5)
			else:
				por_x = absf(move_dir.x) >= absf(move_dir.y)

			if por_x:
				if dx >= 0.0:
					mati.global_position.x = clamp(nx + blk_hw - SPRITE_OX + 0.5, LIMITE_IZQ, LIMITE_DER)
					if mati.velocity.x < 0.0: mati.velocity.x = 0.0
				else:
					mati.global_position.x = clamp(nx - blk_hw - SPRITE_OX - 0.5, LIMITE_IZQ, LIMITE_DER)
					if mati.velocity.x > 0.0: mati.velocity.x = 0.0
			else:
				if dy >= 0.0:
					mati.global_position.y = clamp(ny + blk_bot + 0.5, LIMITE_ARR, LIMITE_ABA)
					if mati.velocity.y < 0.0: mati.velocity.y = 0.0
				else:
					mati.global_position.y = clamp(ny - blk_top - 0.5, LIMITE_ARR, LIMITE_ABA)
					if mati.velocity.y > 0.0: mati.velocity.y = 0.0

		if nubes_nodo != null:
			var vis_x2 : float = mati.global_position.x + SPRITE_OX
			var vis_y2 : float = mati.global_position.y + SPRITE_OY
			for n in nubes_nodo.nubes:
				var cnx : float = float(n["x"])
				var cny : float = float(n["y"])
				var cnr : float = float(n["r"]) * 1.6
				var diff := Vector2(vis_x2 - cnx, vis_y2 - cny)
				var dist := diff.length()
				if dist < cnr and dist > 0.5:
					var push := diff.normalized()
					mati.global_position.x = cnx + push.x * cnr - SPRITE_OX
					mati.global_position.y = cny + push.y * cnr - SPRITE_OY
					var v_in : float = mati.velocity.dot(-push)
					if v_in > 0.0:
						mati.velocity += push * v_in

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
			continue
		var dist = $Mati.global_position.distance_to(npc_nodes[i].global_position)
		if dist < dist_min:
			dist_min    = dist
			npc_cercano = i

	if npc_cercano >= 0:
		if npc_cercano != npc_cercano_prev:
			_animar_npc_pop(npc_cercano)
			npc_cercano_prev = npc_cercano

		var npc_pos : Vector2 = npc_nodes[npc_cercano].global_position
		$BtnInteractuar.position = npc_pos + Vector2(80, -145)

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
	# El jefe final tiene su propia animación de "respiración" continua;
	# no la interrumpimos con el pop para que mantenga su tamaño imponente.
	if NPCS_DATA[idx].get("id", "") == "jefe_hongo":
		return
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

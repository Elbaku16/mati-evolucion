extends Node2D

# ═══════════════════════════════════════════════════════════════
#  MUNDO 1 — PLANETA VERDE
#  El jugador recorre el mundo y habla con 5 NPCs.
#  Cada NPC tiene su historia y su desafío matemático propio.
#  No existe pantalla de selección de secciones.
# ═══════════════════════════════════════════════════════════════

const VELOCIDAD        : float = 280.0
const DIST_INTERACCION : float = 280.0

const LIMITE_IZQ  : float = -1930.0
const LIMITE_DER  : float =  2580.0
const LIMITE_ARR  : float =   480.0
const LIMITE_ABA  : float =  1700.0

# Zona cueva: más allá del mundo → la oscuridad nunca se activa
const CUEVA_INICIO_X : float = 9999.0

# Obstáculos estáticos: Sprite2D centrados — [ cx, cy, half_w, half_h ]
const OBSTACULOS_ESTATICOS : Array = [
	# Cohete estrellado
	[1900.0, 720.0, 130.0, 150.0],
]

const RUTA_SAVE : String = "user://mati_save.json"

# ─────────────────────────────────────────────────────────────
#  DATOS DE LOS 5 NPCs DEL MUNDO 1
#  seccion: ID del desafío (1–5), igual que el sistema de guardado
# ─────────────────────────────────────────────────────────────
const NPCS_DATA : Array = [
	# ── EXPLORACIÓN IZQUIERDA ── Desafíos fáciles al fondo izquierdo
	{
		"id":            "tristan",
		"nombre":        "Tristán",
		"seccion":       1,
		"pos":           Vector2(-1700, 610),   # Extremo izquierdo — ARRIBA en las colinas
		"textura":       "res://assets/npcs/triste.PNG",
		"dialogo":       "¡Hola! Soy Tristán...\nSiempre me pongo triste cuando\nno puedo contar bien mis cosas.\n¿Me ayudas con unas sumitas?",
		"dialogo_hecho": "¡Gracias Mati!\nYa sé cuántas cosas tengo.\n¡Ya no estoy tan triste!"
	},
	# ── ZONA CENTRAL ── Cerca del punto de inicio de Mati
	{
		"id":            "peque",
		"nombre":        "Peque",
		"seccion":       2,
		"pos":           Vector2(-600, 880),    # Izquierda baja — cerca del inicio, primer contacto fácil
		"textura":       "res://assets/npcs/pequeño.PNG",
		"dialogo":       "¡Oye! Soy Peque.\nSoy pequeño pero mis problemas\nde matemáticas son GRANDES.\nNecesito hacer SUMAS más difíciles.",
		"dialogo_hecho": "¡Lo logramos!\nAunque soy pequeño, ahora sé\nsumar números grandes. ¡Gracias!"
	},
	{
		"id":            "nova",
		"nombre":        "Nova",
		"seccion":       5,
		"pos":           Vector2(200, 620),     # Centro — ARRIBA, obliga a explorar la zona alta
		"textura":       "res://assets/npcs/Alien Cool Solo.PNG",
		"dialogo":       "¡Hola! Soy Nova, exploradora galáctica.\nEstaba contando las estrellas del planeta\npero me confundí con las operaciones...\n¿Puedes ayudarme con sumas y restas?",
		"dialogo_hecho": "¡Increíble Mati!\nYa pude terminar mis mapas estelares.\n¡Eres muy listo!"
	},
	# ── EXPLORACIÓN DERECHA ── Desafíos más difíciles al avanzar
	{
		"id":            "zote",
		"nombre":        "Zote",
		"seccion":       3,
		"pos":           Vector2(1500, 880),    # Derecha baja — ABAJO, contraste con Nova que está arriba
		"textura":       "res://assets/npcs/alienzote.PNG",
		"dialogo":       "¡GRRRR! Soy Zote, el gran alien.\nTengo muchas cosas que contar\npero me pierdo en las sumas.\n¡Ayúdame o te enfrento!",
		"dialogo_hecho": "Hmm... impresionante, pequeño.\nSabías más que yo.\n¡Eso no lo olvidaré!"
	},
	# ── CUEVA ── Cosmo se escondió en las cavernas — ¡hay que ir hasta el fondo!
	{
		"id":            "cosmo",
		"nombre":        "Cosmo",
		"seccion":       4,
		"tiene_desafio": true,
		"es_final":      true,
		"pos":           Vector2(2350, 850),    # Extremo derecho — ABAJO en el camino final
		"textura":       "res://assets/npcs/Astronauta Solo.PNG",
		"dialogo":       "¡Mati! ¡Por fin llegaste hasta aquí!\nMi nave se averió y me refugié\nen estas cavernas oscuras...\nPara repararla necesito que ayudes\na los 4 guardianes. ¡Habla con todos!",
		"dialogo_desafio": "¡Muy bien, Mati!\n¡Completaste los 4 guardianes!\nAhora ayúdame a contar las piezas\npara reparar mi nave...\n¡Estas sumas son un poquito\nmás complicadas! ¿Las resolvemos?",
		"dialogo_hecho": "¡¡LO LOGRASTE MATI!!\n¡Reparaste mi nave por completo!\nAhora puedo salir de la cueva\ny volver a casa.\n¡Eres el héroe del Planeta Verde!\nYa puedes seguir al siguiente mundo."
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
		"espalda": "res://assets/personajes/mati_lentes.PNG",   # sin vista trasera → reutilizar frente
	},
}

# ── Estado general ────────────────────────────────────────────
var guardado_node
var monedas_sesion    : int   = 0
var mision_completada : bool  = false
var animacion_lista   : bool  = false
var dialogo_activo    : bool  = false
var texto_completo    : bool  = false
var texto_timer       : float = 0.0
var texto_indice      : int   = 0
var texto_npc_actual  : String = ""
const VELOCIDAD_TEXTO : float = 0.04

var dir_x : float = 0.0
var dir_y : float = 0.0

# ── Vistas direccionales de Mati ──────────────────────────────
var _skin_vistas : Dictionary = {}   # {"frente": Texture2D, "perfil": ..., "espalda": ...}
var _dir_actual  : String = "frente" # "frente" | "espalda" | "perfil"
var _flip_perfil : bool   = false    # true = perfil mirando a la izquierda

# ── Efectos cueva ────────────────────────────────────────────
var cueva_overlay  : ColorRect   = null
var _cueva_canvas  : CanvasLayer = null

# ── Diálogo RPG (portraits + overlay) ────────────────────────
var _rpg_layer    : CanvasLayer   = null
var _rpg_bg       : ColorRect     = null
var _rpg_mati_ret : TextureRect   = null
var _rpg_npc_ret  : TextureRect   = null
var _rpg_dlg_box  : Control       = null   # usa panel_dialogo_npc.gd
var _rpg_lbl_nom  : Label         = null
var _rpg_lbl_txt  : Label         = null
var _rpg_btn_ayd  : TextureButton = null
var _rpg_lbl_cls  : Label         = null
var _rpg_estrellas : Array        = []
var _rpg_mati_dest_x : float      = 0.0
var _rpg_npc_dest_x  : float      = 0.0
var _rpg_npc_size    : Vector2    = Vector2(460.0, 540.0)

# ── NPCs ──────────────────────────────────────────────────────
var nubes_nodo       : Node2D = null   # referencia al script de nubes
var npc_nodes        : Array = []
var npc_cercano      : int   = -1   # índice NPC más próximo (-1 = ninguno)
var npc_activo       : int   = -1   # índice NPC en diálogo
var npc_cercano_prev    : int         = -1
var npc_base_pos        : Array       = []
var tiempo_mundo        : float       = 0.0
var btn_era_visible     : bool        = false
var btn_escala_orig     : Vector2     = Vector2(0.07508756, 0.06985476)
var indicador_estrella  : TextureRect = null
var indicador_wrap_node : Control     = null
var indicador_label0    : Label       = null

# ─────────────────────────────────────────────────────────────
#  INICIALIZACIÓN
# ─────────────────────────────────────────────────────────────
func _ready() -> void:
	guardado_node = load("res://scripts/guardado.gd").new()
	var datos = guardado_node.cargar()

	# Música de exploración
	if Engine.has_singleton("MusicaManager") or get_node_or_null("/root/MusicaManager"):
		get_node("/root/MusicaManager").musica_explorar_mundo(1)

	# Efecto de portal al entrar al mundo
	var _efectos_e = load("res://scripts/efectos_ui.gd")
	if _efectos_e:
		_efectos_e.flash_blanco(get_tree().root)

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

	# Crear NPCs programáticamente en el mundo
	_crear_npcs()
	_actualizar_visual_npcs()

	# Fondo: un solo sprite, sin tiling
	$Fondo.z_index = -2

	# Nubes animadas en el cielo (z=-1, delante del fondo pero detrás de NPCs)
	nubes_nodo = Node2D.new()
	nubes_nodo.set_script(load("res://scripts/efectos_nubes.gd"))
	add_child(nubes_nodo)

	# Estalactitas y niebla de cueva (zona oscura derecha)
	var cueva_nodo := Node2D.new()
	cueva_nodo.set_script(load("res://scripts/efectos_cueva.gd"))
	add_child(cueva_nodo)
	_crear_overlay_cueva()

	# Efectos ambientales: brillitos flotantes
	var efectos := Node2D.new()
	efectos.set_script(load("res://scripts/efectos_ambiente.gd"))
	efectos.z_index = -1
	add_child(efectos)

	# Mariposas y luciérnagas volando por el mundo
	var mariposas := Node2D.new()
	mariposas.set_script(load("res://scripts/efectos_mariposas.gd"))
	mariposas.z_index = 1
	add_child(mariposas)

	# Botones de dirección (D-pad táctil)
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

	# Monedas dispersas en el mundo
	for moneda in get_tree().get_nodes_in_group("moneda"):
		moneda.body_entered.connect(_on_moneda_recolectada.bind(moneda))

	# Zona cohete original: mantener señal vacía para no romper la escena
	if has_node("ZonaCohete"):
		$ZonaCohete.body_entered.connect(func(_b): pass)
		$ZonaCohete.body_exited.connect(func(_b): pass)


	# Animación de entrada del cohete
	_crear_animacion_entrada()
	$AnimEntrada.play("entrada")

	# Decoración ambiental: arbusto con mariposas animado
	_crear_arbusto_mariposas()

	# Puertas matemáticas y dispositivo de memoria
	_crear_puertas_y_dispositivos()

# ─────────────────────────────────────────────────────────────
#  DECORACIÓN: ARBUSTO CON MARIPOSAS ANIMADO
# ─────────────────────────────────────────────────────────────
func _crear_puertas_y_dispositivos() -> void:
	var puerta_script = load("res://scripts/puerta_matematica.gd")
	var puertas_cfg := [
		{"id": 101, "tipo": "puerta",  "nivel": 1, "visual": "puerta",  "monedas": 5,  "pos": Vector2(-900, 820),  "tema": "mundo1"},
		{"id": 102, "tipo": "cofre",   "nivel": 1, "visual": "cofre",   "monedas": 8,  "pos": Vector2( 800, 780),  "tema": "mundo1"},
		{"id": 103, "tipo": "palanca", "nivel": 2, "visual": "palanca", "monedas": 10, "pos": Vector2(1900, 650),  "tema": "mundo1"},
	]
	for cfg in puertas_cfg:
		var p := Node2D.new()
		p.set_script(puerta_script)
		p.position = Vector2(cfg["pos"])
		add_child(p)
		p.configurar({
			"id":      cfg["id"],
			"tipo":    cfg.get("tipo", "auto"),
			"nivel":   cfg.get("nivel", 1),
			"visual":  cfg.get("visual", "puerta"),
			"monedas": cfg.get("monedas", 5),
			"tema":    cfg.get("tema", "mundo1"),
		})

	# Dispositivo de memoria espacial — junto al Cosmo (extremo derecho)
	var mem_script = load("res://scripts/minijuego_memoria.gd")
	if mem_script:
		var dispositivo := ColorRect.new()
		dispositivo.color   = Color(0.1, 0.05, 0.3, 0.9)
		dispositivo.size    = Vector2(60, 80)
		dispositivo.position = Vector2(2200, 790)
		dispositivo.z_index  = 2
		add_child(dispositivo)

		var lbl_d := Label.new()
		lbl_d.text = "🛸"
		lbl_d.add_theme_font_size_override("font_size", 36)
		lbl_d.position = Vector2(5, 8)
		dispositivo.add_child(lbl_d)

		var btn_d := Button.new()
		btn_d.text = "Jugar"
		btn_d.position = Vector2(-10, 85)
		btn_d.size     = Vector2(80, 34)
		btn_d.add_theme_font_size_override("font_size", 15)
		dispositivo.add_child(btn_d)
		btn_d.pressed.connect(func():
			mem_script.guardar_config({
				"titulo":        "Dispositivo Alienígena",
				"nivel_inicio":  2,
				"rondas":        4,
				"monedas":       12,
				"seccion_id":    110,
				"escena_origen": "res://scenes/Mundo1Explorar.tscn"
			})
			TransitionManager.cambiar_escena("res://scenes/MinijuegoMemoria.tscn")
		)

func _crear_arbusto_mariposas() -> void:
	var frames : Array = []
	for i in range(4):
		frames.append("res://assets/animaciones/arbusto_mariposas_%d.png" % i)

	var posiciones := [Vector2(-200, 1020), Vector2(1100, 980)]
	for pos in posiciones:
		var efecto = load("res://scripts/efecto_animado.gd").new()
		add_child(efecto)
		efecto.iniciar(frames, 5.0, true)
		efecto.position = pos
		efecto.scale    = Vector2(0.55, 0.55)
		efecto.z_index  = -1

# ─────────────────────────────────────────────────────────────
#  CREAR NPCs EN EL MUNDO 2D
# ─────────────────────────────────────────────────────────────
var label_npc_nombre : Label = null

func _crear_npcs() -> void:
	var npc_script         = load("res://scripts/npc_personaje.gd")
	var capitan_rayo_script = load("res://scripts/npc_capitan_rayo.gd")

	for npc_data in NPCS_DATA:
		var npc = Node2D.new()

		# Capitán Rayo usa su propio script procedural (sin imagen)
		if npc_data["id"] == "capitan_rayo":
			npc.set_script(capitan_rayo_script)
			npc.position = npc_data["pos"]
			add_child(npc)
			npc.setup(null)
		else:
			npc.set_script(npc_script)
			npc.position = npc_data["pos"]
			add_child(npc)
			var tex : Texture2D = null
			if ResourceLoader.exists(npc_data["textura"]):
				tex = load(npc_data["textura"])
			npc.setup(tex)

		var completado : bool = guardado_node.seccion_completada(npc_data["seccion"])
		npc.marcar_completado(completado)
		npc_nodes.append(npc)
		npc_base_pos.append(npc_data["pos"])


	# Label en CanvasLayer para el nombre del NPC cercano
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
		npc_nodes[i].marcar_completado(guardado_node.seccion_completada(NPCS_DATA[i]["seccion"]))

# ─────────────────────────────────────────────────────────────
#  MUNDO COMPLETO (secciones 1–5)
# ─────────────────────────────────────────────────────────────
func _todas_secciones_completas() -> bool:
	for i in [1, 2, 3, 5]:   # los 4 guardianes del Mundo 1
		if not guardado_node.seccion_completada(i):
			return false
	return true

# Determina si corresponde mostrar el botón de "ayudar" (iniciar desafío)
# para el NPC dado. Para Cosmo (es_final) el desafío propio solo aparece
# después de haber ayudado a los 4 guardianes.
func _debe_mostrar_btn_desafio(npc_data: Dictionary) -> bool:
	if not npc_data.get("tiene_desafio", true):
		return false
	if npc_data.get("es_final", false) and not _todas_secciones_completas():
		return false
	return not guardado_node.seccion_completada(npc_data["seccion"])

# ─────────────────────────────────────────────────────────────
#  ANIMACIÓN DE ENTRADA (cohete aterriza y aparece Mati)
# ─────────────────────────────────────────────────────────────
func _crear_animacion_entrada() -> void:
	var anim = Animation.new()
	anim.length = 3.0

	var track_cohete_pos = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_cohete_pos, "CoheteEntrada:position")
	anim.track_insert_key(track_cohete_pos, 0.0, Vector2($Mati.position.x, -300))
	anim.track_insert_key(track_cohete_pos, 1.2, Vector2($Mati.position.x, $Mati.position.y - 40))
	anim.track_insert_key(track_cohete_pos, 1.5, Vector2($Mati.position.x, $Mati.position.y - 40))
	anim.track_insert_key(track_cohete_pos, 2.5, Vector2($Mati.position.x, -400))

	var track_cohete_vis = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_cohete_vis, "CoheteEntrada:visible")
	anim.track_insert_key(track_cohete_vis, 0.0,  true)
	anim.track_insert_key(track_cohete_vis, 2.5,  true)
	anim.track_insert_key(track_cohete_vis, 2.51, false)

	var track_mati_vis = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_mati_vis, "Mati:visible")
	anim.track_insert_key(track_mati_vis, 0.0,  false)
	anim.track_insert_key(track_mati_vis, 1.5,  false)
	anim.track_insert_key(track_mati_vis, 1.51, true)

	var track_mati_scale = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_mati_scale, "Mati:scale")
	anim.track_insert_key(track_mati_scale, 1.51, Vector2(0.0, 0.0))
	anim.track_insert_key(track_mati_scale, 1.8,  Vector2(1.2, 1.2))
	anim.track_insert_key(track_mati_scale, 2.0,  Vector2(1.0, 1.0))

	var lib = AnimationLibrary.new()
	lib.add_animation("entrada", anim)
	$AnimEntrada.add_animation_library("", lib)
	$AnimEntrada.animation_finished.connect(_on_animacion_entrada_terminada)

	$Mati.visible = false
	$CoheteEntrada.visible = true

func _on_animacion_entrada_terminada(_anim_name: String) -> void:
	animacion_lista = true

# ─────────────────────────────────────────────────────────────
#  DIÁLOGO DEL NPC
# ─────────────────────────────────────────────────────────────
var _panel_bg_npc : Node = null   # instancia del panel dibujado

func _configurar_panel_dialogo() -> void:
	# Ocultar el fondo original (ColorRect azul)
	var cr = $UI/PanelDialogo.get_node_or_null("ColorRect")
	if cr:
		cr.visible = false

	# Crear el panel gráfico naranja-amarillo
	var script = load("res://scripts/panel_dialogo_npc.gd")
	var panel_bg := Control.new()
	panel_bg.set_script(script)
	$UI/PanelDialogo.add_child(panel_bg)
	$UI/PanelDialogo.move_child(panel_bg, 0)
	panel_bg.layout_mode = 1
	panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_bg_npc = panel_bg

	# Texto en color oscuro legible sobre fondo naranja
	$UI/PanelDialogo/LabelTexto.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	# Permitir que LabelNombre sobresalga hacia la pestañita (por encima del panel)
	$UI/PanelDialogo.clip_contents = false
	var ln_cfg = $UI/PanelDialogo/LabelNombre
	ln_cfg.layout_mode = 1   # modo anclado para poder usar anchors/offsets
	ln_cfg.add_theme_color_override("font_color", Color(0.22, 0.06, 0.01))
	ln_cfg.add_theme_font_size_override("font_size", 15)

	# Hint "toca para cerrar" — aparece cuando el texto terminó y no hay desafío pendiente
	var lc := Label.new()
	lc.name = "LabelCerrar"
	lc.text = "▸ Toca para cerrar"
	lc.add_theme_font_size_override("font_size", 13)
	lc.add_theme_color_override("font_color", Color(0.45, 0.18, 0.02, 0.85))
	lc.layout_mode = 1
	lc.anchor_left   = 1.0; lc.anchor_right  = 1.0
	lc.anchor_top    = 1.0; lc.anchor_bottom  = 1.0
	lc.offset_left   = -190.0; lc.offset_right  = -12.0
	lc.offset_top    = -28.0;  lc.offset_bottom = -6.0
	lc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lc.visible = false
	$UI/PanelDialogo.add_child(lc)

func _mostrar_dialogo_npc(idx: int) -> void:
	npc_activo = idx
	var npc_data = NPCS_DATA[idx]

	dialogo_activo   = true
	texto_indice     = 0
	texto_completo   = false

	# Para Cosmo (es_final): tiene 3 estados —
	#  1) faltan guardianes  → "dialogo" (pide ayudar a los 4 guardianes)
	#  2) guardianes listos, falta su propio desafío → "dialogo_desafio"
	#  3) todo completo → "dialogo_hecho"
	if npc_data.get("es_final", false):
		var guardianes_listos = _todas_secciones_completas()
		var propio_completo   = guardado_node.seccion_completada(npc_data["seccion"])
		if not guardianes_listos:
			texto_npc_actual = npc_data["dialogo"]
		elif not propio_completo:
			texto_npc_actual = npc_data.get("dialogo_desafio", npc_data["dialogo"])
		else:
			texto_npc_actual = npc_data["dialogo_hecho"]
	else:
		var completada = guardado_node.seccion_completada(npc_data["seccion"])
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
	# El proyecto corre en 1280×720 (canvas_items stretch).
	var vp   := get_viewport().get_visible_rect().size
	var vp_w := vp.x   # 1280
	var vp_h := vp.y   # 720

	_rpg_bg.size = vp

	# ══════════════════════════════════════════════════════════
	# RETRATOS — grandes, pegados a los bordes de pantalla.
	# 29% de ancho = 371 px. 72% de alto = 518 px.
	# STRETCH_KEEP_ASPECT_COVERED → el personaje LLENA el rect
	# (zoom-in, pequeño recorte de bordes si hace falta).
	#
	# Mati:  visual x=[0 .. port_w]          (borde izquierdo)
	# NPC :  visual x=[vp_w−port_w .. vp_w]  (borde derecho)
	# ══════════════════════════════════════════════════════════
	var port_w := vp_w * 0.29       # 371.2 px  @1280
	var port_h := vp_h * 0.72       # 518.4 px  @720
	var port_y := vp_h - port_h     # 201.6 px  (pegado al fondo)

	# Mati es un poco más pequeño que el NPC (80%) para que luzcan similares.
	# La textura de Mati llena más el frame con COVERED, así que reducimos su rect.
	var mati_w := port_w * 0.80    # ≈ 297 px
	var mati_h := port_h * 0.80    # ≈ 414 px
	var mati_y := vp_h - mati_h    # ≈ 306 px (pegado al fondo)

	_rpg_mati_ret.size = Vector2(mati_w, mati_h)
	_rpg_npc_ret.size  = Vector2(port_w, port_h)

	# Mati (scale.x = -1): position.x = BORDE DERECHO visual.
	# Destino = mati_w → visual abarca [0 .. mati_w].
	_rpg_mati_dest_x       = mati_w
	_rpg_mati_ret.position = Vector2(-mati_w, mati_y)   # empieza off-screen izq

	# NPC: position.x = BORDE IZQUIERDO visual.
	# Destino = vp_w − port_w → visual abarca [vp_w−port_w .. vp_w].
	_rpg_npc_dest_x       = vp_w - port_w
	_rpg_npc_ret.position = Vector2(vp_w + port_w * 0.5, port_y)  # off-screen der

	# ══════════════════════════════════════════════════════════
	# PANEL DE DIÁLOGO — entre los dos retratos.
	# Ancho = vp_w − 2×port_w − 2×margen ≈ 518 px.
	# Alto = 35% del viewport ≈ 252 px — caben texto + botón.
	#
	# El botón JUGAR queda DENTRO de la caja, al fondo.
	# ══════════════════════════════════════════════════════════
	# boton_jugar.png = 420×130 px reales.
	# Con ignore_texture_size=true el botón respeta este size exactamente.
	# Mostramos a 46 px de alto → ancho proporcional ≈ 149 px.
	const BTN_TEX_W : float = 420.0
	const BTN_TEX_H : float = 130.0
	var btn_h : float = 46.0
	var btn_w : float = BTN_TEX_W * (btn_h / BTN_TEX_H)   # ≈ 149 px
	_rpg_btn_ayd.scale = Vector2(1.0, 1.0)
	_rpg_btn_ayd.size  = Vector2(btn_w, btn_h)

	var dlg_gap : float = 10.0
	var dlg_x   : float = mati_w + dlg_gap                              # ~307 px
	var dlg_w   : float = (vp_w - port_w) - mati_w - dlg_gap * 2.0     # ~592 px
	var dlg_h   : float = vp_h * 0.35                                    # 252 px
	var dlg_y   : float = vp_h - dlg_h - 16.0                           # 452 px

	_rpg_dlg_box.size     = Vector2(dlg_w, dlg_h)
	_rpg_dlg_box.position = Vector2(dlg_x, dlg_y)
	if _rpg_dlg_box.has_method("setup"):
		_rpg_dlg_box.call("setup", false)   # pestaña a la izquierda

	# ── Label nombre — sobre la pestaña (tx=20, ty=−32 del panel) ──
	_rpg_lbl_nom.position = Vector2(dlg_x + 20.0, dlg_y - 32.0)
	_rpg_lbl_nom.size     = Vector2(118.0, 38.0)

	# ── Texto — llena la caja dejando espacio para el botón ───
	var txt_pad_top  : float = 10.0
	var btn_reserved : float = btn_h + 18.0   # ~64 px al fondo para el botón + margen
	_rpg_lbl_txt.position = Vector2(dlg_x + 12.0, dlg_y + txt_pad_top)
	_rpg_lbl_txt.size     = Vector2(dlg_w - 24.0, dlg_h - txt_pad_top - btn_reserved)

	# ── Botón JUGAR — centrado, al fondo de la caja con buen margen
	_rpg_btn_ayd.position = Vector2(
		dlg_x + (dlg_w - btn_w) * 0.5,
		dlg_y + dlg_h - btn_h - 12.0
	)

	# ── Hint "toca para cerrar" — dentro de la caja, esquina ─
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
	# Fondo fade-in leve (38% opaco — el mundo se sigue viendo)
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
				var npc_act = NPCS_DATA[npc_activo]
				if _rpg_btn_ayd: _rpg_btn_ayd.visible = _debe_mostrar_btn_desafio(npc_act)
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
		# Mati (flipped, scale.x=-1): position.x es borde derecho visual.
		# Para salir por la izquierda → position.x < 0
		tw.tween_property(_rpg_mati_ret, "position:x", -50.0, 0.25)
		tw.tween_property(_rpg_npc_ret,  "position:x",
						  vp.x + 50.0, 0.25)
		tw.tween_property(_rpg_bg, "color",
						  Color(0.0, 0.0, 0.0, 0.0), 0.25)
		# Al terminar → ocultar capa
		tw.chain().tween_callback(func(): _rpg_layer.visible = false)
	else:
		$UI/PanelDialogo.visible = false

# ─────────────────────────────────────────────────────────────
#  INPUT (teclado + clic en diálogo)
# ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not animacion_lista:
		return

	# Clic durante diálogo → completar texto o cerrar
	if dialogo_activo and event is InputEventMouseButton and event.pressed:
		if not texto_completo:
			# Primer clic: mostrar todo el texto de golpe
			texto_indice = texto_npc_actual.length()
			if _rpg_lbl_txt: _rpg_lbl_txt.text = texto_npc_actual
			texto_completo = true
			if npc_activo >= 0:
				var npc_act2 = NPCS_DATA[npc_activo]
				if _rpg_btn_ayd: _rpg_btn_ayd.visible = _debe_mostrar_btn_desafio(npc_act2)
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
						# Enter: completar texto de golpe
						texto_indice = texto_npc_actual.length()
						if _rpg_lbl_txt: _rpg_lbl_txt.text = texto_npc_actual
						texto_completo = true
						if npc_activo >= 0:
							var npc_enter = NPCS_DATA[npc_activo]
							if _rpg_btn_ayd: _rpg_btn_ayd.visible = _debe_mostrar_btn_desafio(npc_enter)
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

	# Guardar la sección que va a jugarse
	var datos = guardado_node.cargar()
	datos["seccion_actual"] = seccion_id
	var archivo = FileAccess.open(guardado_node._ruta(), FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos))
		archivo.close()

	TransitionManager.cambiar_escena("res://scenes/Mundo1Operaciones.tscn")

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

	# ═══════════════════════════════════════════════════════════
	#  BLOQUEO AABB de NPCs — PRE + POST move_and_slide
	#
	#  CLAVE: el Sprite2D de Mati está en position=(-74,-33)
	#  respecto al CharacterBody2D.  Si calculamos dx desde el CB2D
	#  el lado derecho "se mete" porque el visual está 74u más
	#  a la izquierda que el origen físico.
	#  → Usamos la posición VISUAL (CB2D.x + SPRITE_OX) para medir,
	#    y ajustamos la corrección de posición en consecuencia.
	#
	#  BLK_HW medido desde el CENTRO VISUAL de Mati:
	#    NPC half-w (100) + Mati visual half-w (~80) = 180
	# ═══════════════════════════════════════════════════════════
	const SPRITE_OX : float = -74.0   # offset X sprite → CB2D  (del .tscn)
	const BLK_HW    : float = 180.0   # desde centro visual de Mati al NPC
	const BLK_TOP   : float = 260.0
	const BLK_BOT   : float = 60.0

	var move_dir := Vector2(dir_x, dir_y)

	# ── Función auxiliar inline para aplicar corrección ────────
	# (se repite en PRE y POST con la misma lógica)
	const SPRITE_OY : float = -33.0   # offset Y sprite → CB2D  (del .tscn)

	for _pass in range(2):   # 0 = pre-check, 1 = post-check
		if _pass == 1:
			mati.move_and_slide()   # mover entre los dos checks

		# ── Bloqueo AABB de NPCs ────────────────────────────────
		for i in range(npc_nodes.size()):
			var nx  : float = npc_base_pos[i].x
			var ny  : float = npc_base_pos[i].y

			var escala_npc : float = float(NPCS_DATA[i].get("escala", 1.0))
			var blk_hw  : float = BLK_HW  * escala_npc
			var blk_top : float = BLK_TOP * escala_npc
			var blk_bot : float = BLK_BOT * escala_npc

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
					mati.global_position.x = nx + blk_hw - SPRITE_OX + 0.5
					if mati.velocity.x < 0.0: mati.velocity.x = 0.0
				else:
					mati.global_position.x = nx - blk_hw - SPRITE_OX - 0.5
					if mati.velocity.x > 0.0: mati.velocity.x = 0.0
			else:
				if dy >= 0.0:
					mati.global_position.y = ny + blk_bot + 0.5
					if mati.velocity.y < 0.0: mati.velocity.y = 0.0
				else:
					mati.global_position.y = ny - blk_top - 0.5
					if mati.velocity.y > 0.0: mati.velocity.y = 0.0

		# ── Bloqueo de obstáculos estáticos (cohete, etc.) ─────────
		# Sprite2D centrados → medimos desde centro visual de Mati
		for obs in OBSTACULOS_ESTATICOS:
			var ox   : float = float(obs[0])
			var oy   : float = float(obs[1])
			var ohw  : float = float(obs[2])
			var ohh  : float = float(obs[3])

			var vis_x3 : float = mati.global_position.x + SPRITE_OX
			var vis_y3 : float = mati.global_position.y + SPRITE_OY
			var odx    : float = vis_x3 - ox
			var ody    : float = vis_y3 - oy

			if absf(odx) > ohw or absf(ody) > ohh:
				continue

			var opor_x : bool
			if move_dir.length_squared() < 0.01:
				opor_x = absf(odx) / ohw >= absf(ody) / ohh
			else:
				opor_x = absf(move_dir.x) >= absf(move_dir.y)

			if opor_x:
				if odx >= 0.0:
					mati.global_position.x = ox + ohw - SPRITE_OX + 0.5
					if mati.velocity.x < 0.0: mati.velocity.x = 0.0
				else:
					mati.global_position.x = ox - ohw - SPRITE_OX - 0.5
					if mati.velocity.x > 0.0: mati.velocity.x = 0.0
			else:
				if ody >= 0.0:
					mati.global_position.y = oy + ohh - SPRITE_OY + 0.5
					if mati.velocity.y < 0.0: mati.velocity.y = 0.0
				else:
					mati.global_position.y = oy - ohh - SPRITE_OY - 0.5
					if mati.velocity.y > 0.0: mati.velocity.y = 0.0

		# ── Bloqueo CIRCULAR de nubes ────────────────────────────
		# Las nubes son obstáculos sólidos que Mati no puede atravesar.
		# Radio de bloqueo = radio_visual_nube × 1.6
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
					# Convertir posición visual a CB2D
					mati.global_position.x = cnx + push.x * cnr - SPRITE_OX
					mati.global_position.y = cny + push.y * cnr - SPRITE_OY
					var v_in : float = mati.velocity.dot(-push)
					if v_in > 0.0:
						mati.velocity += push * v_in

	mati.global_position.x = clamp(mati.global_position.x, LIMITE_IZQ, LIMITE_DER)
	mati.global_position.y = clamp(mati.global_position.y, LIMITE_ARR, LIMITE_ABA)

	# ── Overlay cueva: oscurece la pantalla al adentrarse en la cueva ──
	if cueva_overlay != null:
		var mx : float = mati.global_position.x
		var t  : float = clampf((mx - CUEVA_INICIO_X) / 1400.0, 0.0, 1.0)
		var c  : Color = cueva_overlay.color
		c.a = t * 0.70
		cueva_overlay.color = c
		var vp := get_viewport().get_visible_rect().size
		if cueva_overlay.size != vp:
			cueva_overlay.size = vp

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
		var dist = $Mati.global_position.distance_to(npc_nodes[i].global_position)
		if dist < dist_min:
			dist_min    = dist
			npc_cercano = i

	if npc_cercano >= 0:
		# ── Pop squash-and-stretch al acercarse por primera vez ─
		if npc_cercano != npc_cercano_prev:
			_animar_npc_pop(npc_cercano)
			npc_cercano_prev = npc_cercano

		# Mover botón ! encima del NPC (centrado sobre la cabeza)
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
	npc.scale = Vector2(1.0, 1.0)  # reset por si había tween previo
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	# Squash → Stretch → Settle (clásico squash-and-stretch)
	tw.tween_property(npc, "scale", Vector2(1.18, 0.78), 0.09)
	tw.tween_property(npc, "scale", Vector2(0.85, 1.22), 0.13)
	tw.tween_property(npc, "scale", Vector2(1.00, 1.00), 0.20)

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
# ─────────────────────────────────────────────────────────────
#  APLICAR SKIN — escala normalizada para que todas las skins
#  aparezcan al mismo tamaño visual que el personaje default.
#  Referencia: IMG_0430.PNG = 872 × 1001 px
# ─────────────────────────────────────────────────────────────
func _aplicar_skin(skin_id: String) -> void:
	if not has_node("Mati/Sprite2D"):
		return
	var vistas = SKINS_VISTAS.get(skin_id, SKINS_VISTAS["default"])
	_skin_vistas = {}
	for key in vistas:
		var ruta : String = vistas[key]
		if ResourceLoader.exists(ruta):
			_skin_vistas[key] = load(ruta)
	_actualizar_textura_mati()

func _actualizar_textura_mati() -> void:
	if not has_node("Mati/Sprite2D"):
		return
	var sprite := $Mati/Sprite2D
	var tex : Texture2D = _skin_vistas.get(_dir_actual, _skin_vistas.get("frente"))
	if tex == null:
		return
	const TARGET_W : float = 186.8
	const TARGET_H : float = 201.4
	sprite.texture = tex
	sprite.scale   = Vector2(
		-TARGET_W / float(tex.get_width()),
		 TARGET_H / float(tex.get_height())
	)
	# perfil → voltear según dirección; frente/espalda → sin volteo extra
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

# ═══════════════════════════════════════════════════════════════
#  DIÁLOGO ESTILO RPG — construye el overlay una sola vez
# ═══════════════════════════════════════════════════════════════
func _crear_rpg_layer() -> void:
	_rpg_layer = CanvasLayer.new()
	_rpg_layer.layer   = 90   # por encima de todo incluído el overlay de cueva
	_rpg_layer.visible = false
	add_child(_rpg_layer)

	# ── Fondo: leve atenuado negro para que los retratos destaquen
	#    El mundo 1 (planeta verde) se sigue viendo detrás.
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

	# ── Panel de diálogo — mismo script que el panel existente ──
	# Usa el gradiente naranja→amarillo con borde redondeado de panel_dialogo_npc.gd
	_rpg_dlg_box = Control.new()
	_rpg_dlg_box.set_script(load("res://scripts/panel_dialogo_npc.gd"))
	_rpg_dlg_box.layout_mode = 0
	_rpg_dlg_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rpg_layer.add_child(_rpg_dlg_box)

	# ── Label nombre (sobre la pestaña que dibuja el script) ──
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

	# ── Botón "¡Ayudar!" ──────────────────────────────────────
	_rpg_btn_ayd = TextureButton.new()
	_rpg_btn_ayd.layout_mode = 0
	# CRÍTICO: ignore_texture_size=true permite que el botón respete
	# el size que le asignamos, en vez de renderizarse al tamaño real
	# de la textura (420×130 px).
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
#  TILING DEL FONDO
#  Clona el Sprite2D $Fondo hacia izquierda y derecha hasta
#  cubrir el mundo extendido completo.
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

	# Cuántas tiles a izquierda y derecha hacen falta
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

# ─────────────────────────────────────────────────────────────
#  OVERLAY DE CUEVA
#  ColorRect semitransparente sobre CanvasLayer; alpha sube
#  progresivamente conforme Mati entra a la zona oscura.
# ─────────────────────────────────────────────────────────────
func _crear_overlay_cueva() -> void:
	_cueva_canvas = CanvasLayer.new()
	_cueva_canvas.layer = 50   # delante de todo
	add_child(_cueva_canvas)

	cueva_overlay = ColorRect.new()
	# Tinte azul-violeta oscuro (cueva)
	cueva_overlay.color = Color(0.02, 0.0, 0.10, 0.0)
	cueva_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cueva_overlay.layout_mode  = 0
	cueva_overlay.position     = Vector2(0.0, 0.0)
	cueva_overlay.size         = get_viewport().get_visible_rect().size
	_cueva_canvas.add_child(cueva_overlay)

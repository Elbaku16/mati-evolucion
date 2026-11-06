extends Node

# ═══════════════════════════════════════════════════════════════
#  ANIMADOR PERSONAJE — sistema reutilizable de animaciones
#  Usa Tween sobre nodos existentes (Node2D / Control).
#  No requiere spritesheets ni AnimationPlayer en escena.
#
#  Uso:
#    AnimadorPersonaje.idle(sprite_node)
#    AnimadorPersonaje.victoria(sprite_node)
#    AnimadorPersonaje.error_respuesta(sprite_node)
#    AnimadorPersonaje.interaccion(sprite_node)
#    AnimadorPersonaje.daño(sprite_node)
#    AnimadorPersonaje.npc_idle(npc_node)
#    AnimadorPersonaje.npc_reaccion(npc_node)
#    AnimadorPersonaje.npc_alegria(npc_node)
#    AnimadorPersonaje.detener(npc_node)
# ═══════════════════════════════════════════════════════════════

const BOB_ALTURA   : float = 4.0
const BOB_TIEMPO   : float = 1.2
const NPC_BOB_H    : float = 3.0
const NPC_BOB_T    : float = 1.5

# Diccionario de tweens activos por nodo (para cancelarlos)
static var _tweens : Dictionary = {}

# ─────────────────────────────────────────────────────────────
#  MATI — IDLE (bob suave en loop)
# ─────────────────────────────────────────────────────────────
static func idle(nodo: Node2D) -> void:
	detener(nodo)
	var origen := nodo.position
	var tw := nodo.create_tween()
	tw.set_loops()
	tw.tween_property(nodo, "position:y", origen.y - BOB_ALTURA, BOB_TIEMPO * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(nodo, "position:y", origen.y, BOB_TIEMPO * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tweens[nodo] = tw

# ─────────────────────────────────────────────────────────────
#  MATI — CAMINAR (leve rotación de balanceo)
# ─────────────────────────────────────────────────────────────
static func caminar(nodo: Node2D, dir_x: float) -> void:
	# Llama cada frame mientras se mueve
	var angulo_obj := 0.03 * sign(dir_x) if dir_x != 0 else 0.0
	var tw := nodo.create_tween()
	tw.tween_property(nodo, "rotation", angulo_obj, 0.1)
	# No guardamos en _tweens porque es transitorio

# ─────────────────────────────────────────────────────────────
#  MATI — INTERACCIÓN al acercarse a NPC
# ─────────────────────────────────────────────────────────────
static func interaccion(nodo: Node2D) -> void:
	detener(nodo)
	var origen := nodo.position
	var tw := nodo.create_tween()
	tw.tween_property(nodo, "position:y", origen.y - 18, 0.18)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(nodo, "position:y", origen.y, 0.22)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): idle(nodo))

# ─────────────────────────────────────────────────────────────
#  MATI — VICTORIA (salto + escala pulsante)
# ─────────────────────────────────────────────────────────────
static func victoria(nodo: Node2D) -> void:
	detener(nodo)
	_sfx("fanfare")
	var origen_y := nodo.position.y
	var tw := nodo.create_tween()
	# Salto doble
	for _i in range(2):
		tw.tween_property(nodo, "position:y", origen_y - 30, 0.22)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(nodo, "position:y", origen_y, 0.22)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	# Escala pulsante
	tw.tween_property(nodo, "scale", Vector2(1.1, 1.1), 0.12)
	tw.tween_property(nodo, "scale", Vector2(1.0, 1.0), 0.12)
	tw.tween_property(nodo, "scale", Vector2(1.1, 1.1), 0.12)
	tw.tween_property(nodo, "scale", Vector2(1.0, 1.0), 0.12)
	tw.tween_callback(func(): idle(nodo))

# ─────────────────────────────────────────────────────────────
#  MATI — ERROR (shake horizontal)
# ─────────────────────────────────────────────────────────────
static func error_respuesta(nodo: Node2D) -> void:
	detener(nodo)
	_sfx("incorrecto")
	var ox := nodo.position.x
	var tw := nodo.create_tween()
	for offset in [10.0, -10.0, 8.0, -8.0, 5.0, -5.0, 0.0]:
		tw.tween_property(nodo, "position:x", ox + offset, 0.05)
	# Flash rojo
	if nodo is Sprite2D or nodo is TextureRect:
		tw.parallel().tween_property(nodo, "modulate", Color(1.4, 0.3, 0.3), 0.05)
		tw.tween_property(nodo, "modulate", Color(1, 1, 1), 0.3)
	tw.tween_callback(func(): idle(nodo))

# ─────────────────────────────────────────────────────────────
#  MATI — DAÑO (flash + retroceso)
# ─────────────────────────────────────────────────────────────
static func daño(nodo: Node2D) -> void:
	detener(nodo)
	_sfx("golpe")
	var ox := nodo.position.x
	var tw := nodo.create_tween()
	tw.tween_property(nodo, "position:x", ox - 20, 0.1)
	tw.tween_property(nodo, "position:x", ox, 0.2).set_trans(Tween.TRANS_BACK)
	if nodo is Sprite2D:
		tw.parallel().tween_property(nodo, "modulate", Color(1.5, 0.2, 0.2, 0.6), 0.1)
		tw.tween_property(nodo, "modulate", Color(1, 1, 1), 0.3)
	tw.tween_callback(func(): idle(nodo))

# ─────────────────────────────────────────────────────────────
#  NPC — IDLE (bob lento en loop)
# ─────────────────────────────────────────────────────────────
static func npc_idle(nodo: Node2D) -> void:
	detener(nodo)
	var origen := nodo.position
	var tw := nodo.create_tween()
	tw.set_loops()
	tw.tween_property(nodo, "position:y", origen.y - NPC_BOB_H, NPC_BOB_T * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(nodo, "position:y", origen.y, NPC_BOB_T * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tweens[nodo] = tw

# ─────────────────────────────────────────────────────────────
#  NPC — REACCIÓN al hablar con Mati (scale pulse)
# ─────────────────────────────────────────────────────────────
static func npc_reaccion(nodo: Node2D) -> void:
	detener(nodo)
	var tw := nodo.create_tween()
	tw.tween_property(nodo, "scale", Vector2(1.08, 1.08), 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(nodo, "scale", Vector2(1.0,  1.0),  0.15)
	tw.tween_property(nodo, "scale", Vector2(1.06, 1.06), 0.12)
	tw.tween_property(nodo, "scale", Vector2(1.0,  1.0),  0.12)
	tw.tween_callback(func(): npc_idle(nodo))

# ─────────────────────────────────────────────────────────────
#  NPC — ALEGRÍA al completar su desafío
# ─────────────────────────────────────────────────────────────
static func npc_alegria(nodo: Node2D) -> void:
	detener(nodo)
	var origen_y := nodo.position.y
	var tw := nodo.create_tween()
	for _i in range(3):
		tw.tween_property(nodo, "position:y", origen_y - 15, 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(nodo, "position:y", origen_y, 0.18)\
			.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): npc_idle(nodo))

# ─────────────────────────────────────────────────────────────
#  JEFE — ENTRADA DRAMÁTICA (aparece desde arriba)
# ─────────────────────────────────────────────────────────────
static func jefe_entrada(nodo: Node2D, posicion_final: Vector2) -> void:
	detener(nodo)
	nodo.position = Vector2(posicion_final.x, posicion_final.y - 200)
	nodo.modulate.a = 0.0
	var tw := nodo.create_tween()
	tw.tween_property(nodo, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(nodo, "position:y", posicion_final.y, 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): npc_idle(nodo))

# ─────────────────────────────────────────────────────────────
#  JEFE — RECIBE DAÑO (shake + flash)
# ─────────────────────name———————————————————————————————————
static func jefe_daño(nodo: Node2D) -> void:
	var tw := nodo.create_tween()
	var ox := nodo.position.x
	for offset in [12.0, -12.0, 8.0, -8.0, 0.0]:
		tw.tween_property(nodo, "position:x", ox + offset, 0.05)
	tw.parallel().tween_property(nodo, "modulate", Color(1.5, 0.3, 0.3), 0.05)
	tw.tween_property(nodo, "modulate", Color(1, 1, 1), 0.25)

# ─────────────────────────────────────────────────────────────
#  JEFE — ATACA (avanza hacia Mati y regresa)
# ─────────────────────────────────────────────────────────────
static func jefe_ataca(nodo: Node2D, dir_hacia_mati: float) -> void:
	var tw := nodo.create_tween()
	var ox := nodo.position.x
	tw.tween_property(nodo, "position:x", ox + dir_hacia_mati * 40, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(nodo, "position:x", ox, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ─────────────────────────────────────────────────────────────
#  JEFE — DERROTA (encoge y desaparece)
# ─────────────────────────────————————————————————————————————
static func jefe_derrota(nodo: Node2D, callback: Callable = Callable()) -> void:
	detener(nodo)
	var tw := nodo.create_tween()
	tw.tween_property(nodo, "scale", Vector2(0.0, 0.0), 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(nodo, "modulate:a", 0.0, 0.5)
	if callback.is_valid():
		tw.tween_callback(callback)

# ─────────────────────────────────────────────────────────────
#  DETENER animación activa de un nodo
# ─────────────────────────────────────────────────────────────
static func detener(nodo: Node2D) -> void:
	if nodo in _tweens:
		if is_instance_valid(_tweens[nodo]):
			_tweens[nodo].kill()
		_tweens.erase(nodo)
	# Reset transform básico
	nodo.rotation = 0.0
	nodo.scale    = Vector2(1, 1)
	nodo.modulate = Color(1, 1, 1, 1)

# Llama MusicaManager.play_sfx si existe, sin crashear si no hay autoload
static func _sfx(nombre: String) -> void:
	if Engine.has_singleton("MusicaManager"):
		Engine.get_singleton("MusicaManager").play_sfx(nombre)

extends CanvasLayer

# ═══════════════════════════════════════════════════════════════
#  TRANSITION MANAGER — Autoload singleton
#  Cubre los cambios de escena con un fade suave.
#
#  Uso básico:
#    TransitionManager.cambiar_escena("res://scenes/Menu.tscn")
#
#  Con tipo de transición:
#    TransitionManager.cambiar_escena("res://scenes/X.tscn", "blanco")
#    TransitionManager.cambiar_escena("res://scenes/X.tscn", "negro")  ← default
# ═══════════════════════════════════════════════════════════════

var _overlay       : ColorRect
var _duracion      : float = 0.42
var _en_transicion : bool  = false

# Barrido horizontal
var _barra         : ColorRect = null

func _ready() -> void:
	layer = 128

	_overlay = ColorRect.new()
	_overlay.color = Color(0.08, 0.02, 0.18, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 100
	add_child(_overlay)

# ─────────────────────────────────────────────────────────────
func cambiar_escena(ruta: String, tipo: String = "negro") -> void:
	if _en_transicion:
		return
	match tipo:
		"blanco":
			await _fade(ruta, Color(1, 1, 1))
		"barrido":
			await _barrido(ruta)
		_:   # "negro" y cualquier otro
			await _fade(ruta, Color(0.08, 0.02, 0.18))

# ─────────────────────────────────────────────────────────────
#  FADE ESTÁNDAR (negro o blanco)
# ─────────────────────────────────────────────────────────────
func _fade(ruta: String, color_base: Color) -> void:
	_en_transicion = true
	_overlay.color = Color(color_base.r, color_base.g, color_base.b, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 1.0, _duracion)
	await tw.finished

	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame

	var tw2 := create_tween()
	tw2.tween_property(_overlay, "color:a", 0.0, _duracion)
	await tw2.finished

	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_en_transicion = false

# ─────────────────────────────────────────────────────────────
#  BARRIDO HORIZONTAL — cortinilla que entra por la derecha
# ─────────────────────────────────────────────────────────────
func _barrido(ruta: String) -> void:
	_en_transicion = true

	if _barra == null:
		_barra = ColorRect.new()
		_barra.color = Color(0.05, 0.02, 0.15)
		_barra.size  = Vector2(1280, 720)
		_barra.position = Vector2(1280, 0)
		_barra.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(_barra)

	_barra.position = Vector2(1280, 0)
	_barra.visible  = true
	_overlay.color  = Color(0.08, 0.02, 0.18, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_QUART)
	tw.tween_property(_barra, "position:x", 0.0, _duracion * 1.1)
	await tw.finished

	get_tree().change_scene_to_file(ruta)
	await get_tree().process_frame
	await get_tree().process_frame

	var tw2 := create_tween()
	tw2.set_ease(Tween.EASE_IN_OUT)
	tw2.set_trans(Tween.TRANS_QUART)
	tw2.tween_property(_barra, "position:x", -1280.0, _duracion * 1.1)
	await tw2.finished

	_barra.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_en_transicion = false

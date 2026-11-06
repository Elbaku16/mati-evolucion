extends CanvasLayer

# ═══════════════════════════════════════════════════════════════
#  TRANSITION MANAGER — Autoload singleton
#  Cubre los cambios de escena con un fade negro suave.
#  Uso: TransitionManager.cambiar_escena("res://scenes/Menu.tscn")
# ═══════════════════════════════════════════════════════════════

var _overlay   : ColorRect
var _duracion  : float = 0.45
var _en_transicion : bool = false

func _ready() -> void:
	layer = 128

	_overlay = ColorRect.new()
	_overlay.color = Color(0.08, 0.02, 0.18, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 100
	add_child(_overlay)

func cambiar_escena(ruta: String) -> void:
	if _en_transicion:
		return
	_en_transicion = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # bloquea clics durante fade

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

extends CanvasLayer

# ═══════════════════════════════════════════════════════════════
#  TRANSITION MANAGER — Autoload singleton
#  Cubre los cambios de escena con un fade negro suave.
#  Uso: TransitionManager.cambiar_escena("res://scenes/Menu.tscn")
# ═══════════════════════════════════════════════════════════════

var _overlay : ColorRect
var _duracion : float = 0.18   # segundos del fade

func _ready() -> void:
	layer = 128   # encima de absolutamente todo

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 100
	add_child(_overlay)

## Cambia de escena con fade-out → fade-in suave
func cambiar_escena(ruta: String) -> void:
	# Fade out
	var tw := create_tween()
	tw.tween_property(_overlay, "color:a", 1.0, _duracion)
	await tw.finished

	get_tree().change_scene_to_file(ruta)

	# Esperar un frame para que la nueva escena cargue
	await get_tree().process_frame
	await get_tree().process_frame

	# Fade in
	var tw2 := create_tween()
	tw2.tween_property(_overlay, "color:a", 0.0, _duracion)

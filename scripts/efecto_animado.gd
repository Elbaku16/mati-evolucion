extends AnimatedSprite2D

# ═══════════════════════════════════════════════════════════════
#  EFECTO ANIMADO GENÉRICO
#  Crea una animación en bucle a partir de una lista de rutas PNG
#  (fotogramas extraídos de un GIF original).
#
#  Uso:
#    var efecto = load("res://scripts/efecto_animado.gd").new()
#    add_child(efecto)
#    efecto.iniciar(["res://.../frame_0.png", "res://.../frame_1.png", ...], 6.0, true)
#    efecto.position = Vector2(x, y)
#    efecto.scale    = Vector2(s, s)
# ═══════════════════════════════════════════════════════════════

func iniciar(rutas: Array, fps: float = 6.0, loop: bool = true) -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("anim")
	frames.set_animation_speed("anim", fps)
	frames.set_animation_loop("anim", loop)
	for ruta in rutas:
		if ResourceLoader.exists(ruta):
			frames.add_frame("anim", load(ruta))
	sprite_frames = frames
	animation = "anim"
	play("anim")

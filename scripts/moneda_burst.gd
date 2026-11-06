extends Node

# ═══════════════════════════════════════════════════════════════
#  MONEDA BURST — estrellas doradas al recolectar una moneda
#  Uso: MonedaBurst.lanzar(parent_node, posicion_global)
# ═══════════════════════════════════════════════════════════════

static func lanzar(parent: Node, pos: Vector2) -> void:
	var host := Node2D.new()
	host.global_position = pos
	parent.add_child(host)

	var p := CPUParticles2D.new()
	p.emitting           = false
	p.one_shot           = true
	p.explosiveness      = 0.95
	p.amount             = 18
	p.lifetime           = 0.7
	p.speed_scale        = 1.0

	# Dirección: explosión circular
	p.direction          = Vector2(0, -1)
	p.spread             = 180.0
	p.gravity            = Vector2(0, 280)
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 260.0

	# Tamaño
	p.scale_amount_min   = 6.0
	p.scale_amount_max   = 12.0

	# Color dorado → transparente
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.92, 0.1, 1.0))   # amarillo dorado
	grad.add_point(0.5, Color(1.0, 0.65, 0.0, 1.0)) # naranja
	grad.add_point(1.0, Color(1.0, 1.0, 0.4, 0.0))  # fade out
	p.color_ramp = grad

	# Forma de estrella usando cuadrado rotado
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0

	host.add_child(p)
	p.emitting = true

	# Auto-limpiar
	var timer := host.get_tree().create_timer(1.2)
	timer.timeout.connect(func(): host.queue_free())

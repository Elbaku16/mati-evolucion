extends Control

func _ready() -> void:
	$Planeta1.pressed.connect(_on_planeta1_presionado)
	$Planeta2.pressed.connect(_on_planeta2_presionado)
	$Planeta3.pressed.connect(_on_planeta3_presionado)

func _on_planeta1_presionado() -> void:
	print("Nivel 1 seleccionado!")

func _on_planeta2_presionado() -> void:
	print("Nivel 2 seleccionado!")

func _on_planeta3_presionado() -> void:
	print("Nivel 3 seleccionado!")

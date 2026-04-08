extends Control

func _ready() -> void:
	$BtnJugar.pressed.connect(_on_jugar_presionado)

func _on_jugar_presionado() -> void:
	get_tree().change_scene_to_file("res://scenes/Diagnostico.tscn")

extends CanvasLayer

func _ready() -> void:
	# Esto es lo más importante:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func _on_boton_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_boton_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()

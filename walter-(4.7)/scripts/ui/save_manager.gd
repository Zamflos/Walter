extends Node

const SAVE_PATH := "user://save.cfg"

func existe_partida() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func guardar(jugador: Node) -> void:
	if not jugador:
		return
	var config := ConfigFile.new()
	config.set_value("save", "position", jugador.global_position)
	config.set_value("save", "salud", jugador.salud_actual)
	config.set_value("save", "tanques", jugador.tanques_reserva)
	config.save(SAVE_PATH)
	print("Partida guardada")

func cargar(jugador: Node) -> bool:
	if not existe_partida() or not jugador:
		return false
	
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	
	jugador.global_position = config.get_value("save", "position")
	jugador.salud_actual = config.get_value("save", "salud", 100.0)
	jugador.tanques_reserva = config.get_value("save", "tanques", 3)
	
	if jugador.has_signal("salud_cambiada"):
		jugador.salud_cambiada.emit(jugador.salud_actual, jugador.tanques_reserva)
	
	print("Partida cargada")
	return true

func borrar() -> void:
	if existe_partida():
		DirAccess.remove_absolute(SAVE_PATH)
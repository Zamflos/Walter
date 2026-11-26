extends Node

# Autoload: carga los ajustes de audio al iniciar el juego
const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	_asegurar_buses()
	cargar_ajustes()

func _asegurar_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")

func cargar_ajustes() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	if config.has_section_key("audio", "master"):
		var v: float = config.get_value("audio", "master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(v))

	if config.has_section_key("audio", "music"):
		var bus := AudioServer.get_bus_index("Music")
		if bus >= 0:
			var v: float = config.get_value("audio", "music")
			AudioServer.set_bus_volume_db(bus, linear_to_db(v))

	if config.has_section_key("audio", "sfx"):
		var bus := AudioServer.get_bus_index("SFX")
		if bus >= 0:
			var v: float = config.get_value("audio", "sfx")
			AudioServer.set_bus_volume_db(bus, linear_to_db(v))

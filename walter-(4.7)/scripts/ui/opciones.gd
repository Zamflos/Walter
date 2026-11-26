extends Control

# Menú de opciones básico para móvil
# - Volumen Maestro / Música / Efectos
# - Guarda en user://settings.cfg
# Pantalla completa desactivada en móvil (no es útil)

@onready var slider_master: HSlider = $Panel/VBox/Master/Slider
@onready var slider_music: HSlider = $Panel/VBox/Music/Slider
@onready var slider_sfx: HSlider = $Panel/VBox/SFX/Slider
@onready var check_fullscreen: CheckButton = $Panel/VBox/Fullscreen
@onready var btn_volver: Button = $Panel/VBox/BtnVolver

const SETTINGS_PATH := "user://settings.cfg"

func _ready() -> void:
	# Ocultar pantalla completa en móvil
	if OS.has_feature("mobile"):
		check_fullscreen.visible = false

	# Conectar señales
	slider_master.value_changed.connect(_on_master_changed)
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	check_fullscreen.toggled.connect(_on_fullscreen_toggled)
	btn_volver.pressed.connect(_on_volver_pressed)

	# Cargar y aplicar
	cargar_ajustes()
	_actualizar_controles()

func _actualizar_controles() -> void:
	slider_master.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	var bus_music := AudioServer.get_bus_index("Music")
	if bus_music >= 0:
		slider_music.value = db_to_linear(AudioServer.get_bus_volume_db(bus_music))
	var bus_sfx := AudioServer.get_bus_index("SFX")
	if bus_sfx >= 0:
		slider_sfx.value = db_to_linear(AudioServer.get_bus_volume_db(bus_sfx))
	check_fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_master_changed(valor: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(valor))
	guardar_ajustes()

func _on_music_changed(valor: float) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(valor))
	guardar_ajustes()

func _on_sfx_changed(valor: float) -> void:
	var bus := AudioServer.get_bus_index("SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(valor))
	guardar_ajustes()

func _on_fullscreen_toggled(activado: bool) -> void:
	if OS.has_feature("mobile"):
		return
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	guardar_ajustes()

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/Main_menu.tscn")

func guardar_ajustes() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", slider_master.value)
	config.set_value("audio", "music", slider_music.value)
	config.set_value("audio", "sfx", slider_sfx.value)
	config.set_value("video", "fullscreen", check_fullscreen.button_pressed)
	config.save(SETTINGS_PATH)

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

	if config.has_section_key("video", "fullscreen") and not OS.has_feature("mobile"):
		var full: bool = config.get_value("video", "fullscreen")
		if full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

extends CanvasLayer

@onready var btn_continuar: Button = get_node_or_null("Panel/VBox/BtnContinuar")
@onready var btn_guardar: Button = get_node_or_null("Panel/VBox/BtnGuardar")
@onready var btn_cargar: Button = get_node_or_null("Panel/VBox/BtnCargar")
@onready var btn_menu: Button = get_node_or_null("Panel/VBox/BtnMenu")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if btn_continuar:
		btn_continuar.pressed.connect(_on_continuar)
	if btn_guardar:
		btn_guardar.pressed.connect(_on_guardar)
	if btn_cargar:
		btn_cargar.pressed.connect(_on_cargar)
	if btn_menu:
		btn_menu.pressed.connect(_on_menu)

func pausar() -> void:
	get_tree().paused = true
	visible = true

func despausar() -> void:
	get_tree().paused = false
	visible = false

func _on_continuar() -> void:
	despausar()

func _on_guardar() -> void:
	var jugador = get_tree().get_first_node_in_group("jugadores")
	if jugador:
		var config := ConfigFile.new()
		config.set_value("save", "position", jugador.global_position)
		config.set_value("save", "salud", jugador.salud_actual)
		config.set_value("save", "tanques", jugador.tanques_reserva)
		config.save("user://save.cfg")
		print("Partida guardada")
	despausar()

func _on_cargar() -> void:
	var config := ConfigFile.new()
	if config.load("user://save.cfg") != OK:
		print("No hay partida guardada")
		return
	
	var jugador = get_tree().get_first_node_in_group("jugadores")
	if jugador:
		jugador.global_position = config.get_value("save", "position")
		jugador.salud_actual = config.get_value("save", "salud")
		jugador.tanques_reserva = config.get_value("save", "tanques")
		if jugador.has_signal("salud_cambiada"):
			jugador.salud_cambiada.emit(jugador.salud_actual, jugador.tanques_reserva)
		print("Partida cargada")
	despausar()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/Main_menu.tscn")

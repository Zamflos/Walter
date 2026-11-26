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
	SaveManager.guardar(jugador)
	despausar()

func _on_cargar() -> void:
	var jugador = get_tree().get_first_node_in_group("jugadores")
	SaveManager.cargar(jugador)
	despausar()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menus/Main_menu.tscn")

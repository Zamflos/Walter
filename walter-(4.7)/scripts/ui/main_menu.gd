extends Control

@onready var btn_iniciar = $Botones/BtnIniciar
@onready var btn_cargar = $Botones/BtnCargar
@onready var btn_opciones = $Botones/BtnOpciones
@onready var btn_salir = $Botones/BtnSalir

func _ready():
	btn_iniciar.pressed.connect(_on_iniciar_pressed)
	btn_cargar.pressed.connect(_on_cargar_pressed)
	btn_opciones.pressed.connect(_on_opciones_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)
	
	# Mostrar u ocultar el botón según exista partida
	btn_cargar.visible = SaveManager.existe_partida()
	btn_iniciar.grab_focus()

func _on_iniciar_pressed():
	# Nueva partida (borra el save anterior si quieres)
	# SaveManager.borrar()
	get_tree().change_scene_to_file("res://scenes/levels/NivelBase.tscn")

func _on_cargar_pressed():
	# Marca que hay que cargar al entrar al nivel
	SaveManager.set_meta("cargar_al_iniciar", true)
	get_tree().change_scene_to_file("res://scenes/levels/NivelBase.tscn")

func _on_opciones_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/Opciones.tscn")

func _on_salir_pressed():
	get_tree().quit()

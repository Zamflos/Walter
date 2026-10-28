extends Control

@onready var btn_iniciar = $Botones/BtnIniciar
@onready var btn_opciones = $Botones/BtnOpciones
@onready var btn_salir = $Botones/BtnSalir

func _ready():
	btn_iniciar.pressed.connect(_on_iniciar_pressed)
	btn_opciones.pressed.connect(_on_opciones_pressed)
	btn_salir.pressed.connect(_on_salir_pressed)
	btn_iniciar.grab_focus()  # para poder usar teclado/control

func _on_iniciar_pressed():
	get_tree().change_scene_to_file("res://NivelBase.tscn")

func _on_opciones_pressed():
	get_tree().change_scene_to_file("res://Opciones.tscn")

func _on_salir_pressed():
	get_tree().quit()

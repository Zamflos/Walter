extends CanvasLayer

@onready var barra_salud = get_node_or_null("BarraSalud")
@onready var barra_bilis = get_node_or_null("Barra de Bilis")
@onready var label_tanques = get_node_or_null("LabelTanques")

# Las barras que ya tienes en HUB
@onready var tanque1 = get_node_or_null("tanques H2O")
@onready var tanque2 = get_node_or_null("tanques H2O2")
@onready var tanque3 = get_node_or_null("tanques H2O3")

func _ready() -> void:
	# Buscar al jugador correctamente (grupo en plural)
	var jugador = get_tree().get_first_node_in_group("jugadores")
	if jugador:
		if jugador.has_signal("salud_cambiada"):
			jugador.salud_cambiada.connect(_on_salud_cambiada)
		if jugador.has_signal("bilis_cambiada"):
			jugador.bilis_cambiada.connect(_on_bilis_cambiada)
		print("UI conectada al jugador correctamente")
	else:
		print("No se encontró jugador en el grupo 'jugadores'")

func _on_salud_cambiada(salud: float, tanques: int) -> void:
	if barra_salud:
		barra_salud.value = salud
	
	# Actualizar los 3 tanques visuales
	if tanque1: tanque1.value = 100 if tanques >= 1 else 0
	if tanque2: tanque2.value = 100 if tanques >= 2 else 0
	if tanque3: tanque3.value = 100 if tanques >= 3 else 0
	
	print("Salud actual: ", salud, " | Tanques: ", tanques)

func _on_bilis_cambiada(nuevo_valor: float) -> void:
	if barra_bilis:
		barra_bilis.value = nuevo_valor

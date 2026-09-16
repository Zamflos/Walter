extends CanvasLayer

# Nodos de la Interfaz (Asegúrate de que tus nodos en la escena se llamen así)
@onready var barra_salud = $BarraSalud             # TextureProgressBar o ProgressBar
@onready var barra_bilis = $BarraBilis             # TextureProgressBar o ProgressBar
@onready var label_tanques = $LabelTanques         # Label para mostrar tanques/vidas
@onready var panel_inventario = $PanelInventario   # Control o Panel del Inventario

func _ready() -> void:
	# Ocultar el inventario al iniciar la partida
	if panel_inventario:
		panel_inventario.visible = false

	# Buscar al jugador en el grupo "jugador" y conectar las señales
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		jugador.salud_cambiada.connect(_on_salud_cambiada)
		jugador.bilis_cambiada.connect(_on_bilis_cambiada)
		jugador.inventario_alternado.connect(_on_inventario_alternado)

func _on_salud_cambiada(salud: float, tanques: int) -> void:
	if barra_salud:
		barra_salud.value = salud
	if label_tanques:
		label_tanques.text = "Tanques: " + str(tanques)

func _on_bilis_cambiada(nuevo_valor: float) -> void:
	if barra_bilis:
		barra_bilis.value = nuevo_valor

func _on_inventario_alternado() -> void:
	if panel_inventario:
		panel_inventario.visible = not panel_inventario.visible

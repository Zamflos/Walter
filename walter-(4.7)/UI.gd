extends CanvasLayer

@onready var barra_salud: ProgressBar = $BarraSalud
@onready var barra_bilis: ProgressBar = $BarraBilis
@onready var label_tanques: Label = $LabelTanques
@onready var panel_inventario: Panel = $PanelInventario

@onready var tanque1: ColorRect = $Tanque1
@onready var tanque2: ColorRect = $Tanque2
@onready var tanque3: ColorRect = $Tanque3

func _ready() -> void:
	if panel_inventario:
		panel_inventario.visible = false

	var jugador = get_tree().get_first_node_in_group("jugadores")
	if jugador:
		if jugador.has_signal("salud_cambiada"):
			jugador.salud_cambiada.connect(_on_salud_cambiada)
		if jugador.has_signal("bilis_cambiada"):
			jugador.bilis_cambiada.connect(_on_bilis_cambiada)
		if jugador.has_signal("inventario_alternado"):
			jugador.inventario_alternado.connect(_on_inventario_alternado)

func _on_salud_cambiada(salud: float, tanques: int) -> void:
	if barra_salud:
		barra_salud.value = salud
	
	# Actualizar visual de los 3 tanques
	actualizar_tanques(tanques)

func actualizar_tanques(cantidad: int) -> void:
	# Tanque lleno = azul brillante | Tanque roto = gris oscuro
	var color_lleno = Color(0.2, 0.7, 0.95, 1)
	var color_roto = Color(0.25, 0.25, 0.25, 0.7)
	
	if tanque1:
		tanque1.color = color_lleno if cantidad >= 1 else color_roto
	if tanque2:
		tanque2.color = color_lleno if cantidad >= 2 else color_roto
	if tanque3:
		tanque3.color = color_lleno if cantidad >= 3 else color_roto

func _on_bilis_cambiada(nuevo_valor: float) -> void:
	if barra_bilis:
		barra_bilis.value = nuevo_valor

func _on_inventario_alternado() -> void:
	if panel_inventario:
		panel_inventario.visible = not panel_inventario.visible
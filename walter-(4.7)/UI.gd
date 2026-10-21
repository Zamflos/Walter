extends CanvasLayer

@onready var barra_salud: ProgressBar = $BarraSalud
@onready var barra_bilis: ProgressBar = $BarraBilis
@onready var label_tanques: Label = $LabelTanques
@onready var panel_inventario: Panel = $PanelInventario

# Exportamos las dos texturas para asignarlas fácilmente desde el Inspector
@export var textura_tanque_lleno: Texture2D
@export var textura_tanque_roto: Texture2D

# Cambiados de ColorRect a TextureRect
@onready var tanque1: TextureRect = $Tanque1
@onready var tanque2: TextureRect = $Tanque2
@onready var tanque3: TextureRect = $Tanque3

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
	
	# Actualizar visual de los 3 tanques con las imágenes correspondientes
	actualizar_tanques(tanques)

func actualizar_tanques(cantidad: int) -> void:
	# Si la cantidad de tanques es suficiente, se asigna la textura llena; si no, la de tanque roto
	if tanque1:
		tanque1.texture = textura_tanque_lleno if cantidad >= 1 else textura_tanque_roto
	if tanque2:
		tanque2.texture = textura_tanque_lleno if cantidad >= 2 else textura_tanque_roto
	if tanque3:
		tanque3.texture = textura_tanque_lleno if cantidad >= 3 else textura_tanque_roto

func _on_bilis_cambiada(nuevo_valor: float) -> void:
	if barra_bilis:
		barra_bilis.value = nuevo_valor

func _on_inventario_alternado() -> void:
	if panel_inventario:
		panel_inventario.visible = not panel_inventario.visible

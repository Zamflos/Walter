extends CharacterBody2D

# --- Movimiento ---
@export var velocidad: float = 200.0
@export var fuerza_salto: float = -350.0
@export var gravedad: float = 980.0

# --- Dash ---
@export var velocidad_dash: float = 600.0
@export var duracion_dash: float = 0.2
@export var recarga_dash: float = 1.0
var esta_haciendo_dash: bool = false
var puede_hacer_dash: bool = true

# --- Salud y Vidas ---
@export var salud_maxima: float = 100.0
var salud_actual: float = 100.0
@export var tanques_reserva: int = 3

# --- Energía (Barra de Bilis) ---
@export var bilis_maxima: float = 100.0
var bilis_actual: float = 0.0
@export var ganancia_bilis_por_golpe: float = 15.0
@export var costo_curacion: float = 30.0
@export var curacion_cantidad: float = 25.0

# Signals
signal salud_cambiada(salud, tanques)
signal bilis_cambiada(nuevo_valor)
signal inventario_alternado()

func _ready() -> void:
	salud_actual = salud_maxima
	emit_signal("salud_cambiada", salud_actual, tanques_reserva)
	emit_signal("bilis_cambiada", bilis_actual)

func _physics_process(delta: float) -> void:
	# Si está ejecutando el Dash, omite la física normal
	if esta_haciendo_dash:
		move_and_slide()
		return

	# Gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta

	# Salto (Tecla W)
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	# Movimiento Izquierda / Derecha (Teclas A y D)
	var direccion := Input.get_axis("mover_izquierda", "mover_derecha")
	if direccion != 0:
		velocity.x = direccion * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)

	move_and_slide()

	# --- Acciones y Habilidades ---
	
	# Dash (Shift Izq)
	if Input.is_action_just_pressed("dash") and puede_hacer_dash:
		ejecutar_dash(direccion)

	# Ataque Básico (Clic Izquierdo)
	if Input.is_action_just_pressed("atacar"):
		atacar()

	# Curación (Tecla F)
	if Input.is_action_just_pressed("curar"):
		intentar_curacion()

	# Abrir/Cerrar Inventario (Tecla Tab)
	if Input.is_action_just_pressed("inventario"):
		emit_signal("inventario_alternado")

func ejecutar_dash(dir: float) -> void:
	esta_haciendo_dash = true
	puede_hacer_dash = false
	
	# Si no hay dirección pulsada, toma hacia donde mira el personaje
	var direccion_dash = dir if dir != 0 else (1.0 if velocity.x >= 0 else -1.0)
	velocity.x = direccion_dash * velocidad_dash
	velocity.y = 0 # Mantiene altura durante el dash

	# Temporizador de la duración del Dash
	await get_tree().create_timer(duracion_dash).timeout
	esta_haciendo_dash = false

	# Temporizador de recarga (Cooldown)
	await get_tree().create_timer(recarga_dash).timeout
	puede_hacer_dash = true

func atacar() -> void:
	recuperar_bilis(ganancia_bilis_por_golpe)

func recuperar_bilis(cantidad: float) -> void:
	bilis_actual = clamp(bilis_actual + cantidad, 0.0, bilis_maxima)
	emit_signal("bilis_cambiada", bilis_actual)

func intentar_curacion() -> void:
	if bilis_actual >= costo_curacion and salud_actual < salud_maxima:
		bilis_actual -= costo_curacion
		curar(curacion_cantidad)
		emit_signal("bilis_cambiada", bilis_actual)

func recibir_danio(cantidad: float) -> void:
	salud_actual -= cantidad
	if salud_actual <= 0:
		if tanques_reserva > 0:
			tanques_reserva -= 1
			salud_actual = salud_maxima
		else:
			morir()
			return
	emit_signal("salud_cambiada", salud_actual, tanques_reserva)

func curar(cantidad: float) -> void:
	salud_actual = clamp(salud_actual + cantidad, 0.0, salud_maxima)
	emit_signal("salud_cambiada", salud_actual, tanques_reserva)

func morir() -> void:
	get_tree().reload_current_scene()

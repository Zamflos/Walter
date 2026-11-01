extends Node2D
# Gancho: va como hijo del jugador.
# Estructura:
#   Gancho (Node2D)  <- este script
#   ├── Cuerda (Line2D)
#   └── Punta (Sprite2D o AnimatedSprite2D)

enum Estado { INACTIVO, LANZANDO, ENGANCHADO, REGRESANDO }

@export var alcance_maximo: float = 1400.0      # qué tan lejos llega el gancho
@export var rapidez_lanzamiento: float = 6000.0 # qué tan rápido viaja la punta
@export var rapidez_regreso: float = 8000.0     # qué tan rápido regresa si no pega
@export var recarga: float = 0.3
@export_flags_2d_physics var capas_enganchables: int = 1  # capas de colisión donde se puede enganchar
@export var largo_arpon: float = 0.0  # largo del sprite del arpón: la cuerda se amarra en la parte de atrás

@onready var cuerda: Line2D = $Cuerda
@onready var punta: Node2D = $Punta

var estado: Estado = Estado.INACTIVO
var punto_enganche: Vector2 = Vector2.ZERO
var direccion: Vector2 = Vector2.RIGHT
var distancia_recorrida: float = 0.0
var tiempo_recarga: float = 0.0
var posicion_x_base: float = 0.0

func _ready() -> void:
	# La punta se mueve en coordenadas del mundo, no sigue al jugador
	punta.top_level = true
	posicion_x_base = absf(position.x)
	ocultar()
	configurar_control()

# Clic derecho o tecla E
func configurar_control() -> void:
	if InputMap.has_action("gancho"):
		return
	InputMap.add_action("gancho")
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("gancho", clic)
	var tecla := InputEventKey.new()
	tecla.physical_keycode = KEY_E
	InputMap.action_add_event("gancho", tecla)

func _physics_process(delta: float) -> void:
	# El gancho sale de la mano del lado hacia donde mira el jugador
	var jugador := get_parent()
	if "mirando" in jugador:
		position.x = posicion_x_base * jugador.mirando

	if tiempo_recarga > 0.0:
		tiempo_recarga -= delta

	match estado:
		Estado.INACTIVO:
			if Input.is_action_just_pressed("gancho") and tiempo_recarga <= 0.0:
				lanzar(get_global_mouse_position())
		Estado.LANZANDO:
			avanzar_punta(delta)
		Estado.ENGANCHADO:
			punta.global_position = punto_enganche
		Estado.REGRESANDO:
			regresar_punta(delta)

	actualizar_cuerda()

func lanzar(objetivo: Vector2) -> void:
	direccion = (objetivo - global_position).normalized()
	if direccion == Vector2.ZERO:
		return
	punta.global_position = global_position
	punta.rotation = direccion.angle()
	distancia_recorrida = 0.0
	punta.visible = true
	cuerda.visible = true
	estado = Estado.LANZANDO
	animar("lanzando")

func avanzar_punta(delta: float) -> void:
	var paso: float = rapidez_lanzamiento * delta
	var desde: Vector2 = punta.global_position
	var hasta: Vector2 = desde + direccion * paso

	# Revisa si en este tramo la punta toca el mapa
	var consulta := PhysicsRayQueryParameters2D.create(desde, hasta, capas_enganchables)
	var jugador := get_parent()
	if jugador is CollisionObject2D:
		consulta.exclude = [jugador.get_rid()]
	var choque: Dictionary = get_world_2d().direct_space_state.intersect_ray(consulta)

	if not choque.is_empty():
		punto_enganche = choque.position
		punta.global_position = punto_enganche
		estado = Estado.ENGANCHADO
		animar("clavado")
		return

	punta.global_position = hasta
	distancia_recorrida += paso
	if distancia_recorrida >= alcance_maximo:
		empezar_regreso()

func regresar_punta(delta: float) -> void:
	var hacia: Vector2 = global_position - punta.global_position
	var paso: float = rapidez_regreso * delta
	if hacia.length() <= paso:
		ocultar()
		estado = Estado.INACTIVO
		tiempo_recarga = recarga
	else:
		punta.global_position += hacia.normalized() * paso
		punta.rotation = (-hacia).angle()

func soltar() -> void:
	if estado == Estado.ENGANCHADO or estado == Estado.LANZANDO:
		empezar_regreso()

func empezar_regreso() -> void:
	estado = Estado.REGRESANDO
	animar("regresando")

# Reproduce una animación si la Punta es un AnimatedSprite2D y tiene esa animación.
# Si la Punta es un Sprite2D normal, no hace nada.
func animar(nombre: String) -> void:
	if not punta is AnimatedSprite2D:
		return
	var anim := punta as AnimatedSprite2D
	if anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation(nombre):
		anim.play(nombre)
	elif nombre == "regresando" and anim.sprite_frames.has_animation("lanzando"):
		anim.play("lanzando")   # si no hay animación de regreso, usa la de lanzar

func esta_enganchado() -> bool:
	return estado == Estado.ENGANCHADO

func ocultar() -> void:
	punta.visible = false
	cuerda.visible = false

func actualizar_cuerda() -> void:
	if not cuerda.visible:
		return
	var cola: Vector2 = punta.global_position - Vector2.RIGHT.rotated(punta.rotation) * largo_arpon
	cuerda.points = PackedVector2Array([Vector2.ZERO, to_local(cola)])

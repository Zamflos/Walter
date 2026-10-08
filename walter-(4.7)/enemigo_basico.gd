extends CharacterBody2D

# --- Estadísticas ---
@export var salud_maxima: float = 50.0
var salud_actual: float = 50.0

@export var velocidad: float = 90.0
@export var dano_contacto: float = 15.0
@export var distancia_deteccion: float = 300.0   # Distancia a la que detecta al jugador

# --- Referencias ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Cambia el nombre si es diferente
@onready var area_dano: Area2D = $AreaDano                 # Área para hacer daño por contacto

var jugador: Node2D = null
var puede_hacer_dano: bool = true

func _ready() -> void:
	add_to_group("enemigos")
	salud_actual = salud_maxima
	
	# Conectar el área de daño (si la tienes)
	if area_dano:
		area_dano.body_entered.connect(_on_area_dano_body_entered)

func _physics_process(delta: float) -> void:
	# Buscar al jugador si aún no lo tenemos
	if jugador == null:
		var jugadores = get_tree().get_nodes_in_group("jugadores")
		if jugadores.size() > 0:
			jugador = jugadores[0]
	
	if jugador == null:
		return
	
	# Solo perseguir si está dentro del rango de detección
	var distancia = global_position.distance_to(jugador.global_position)
	
	if distancia <= distancia_deteccion:
		var direccion = (jugador.global_position - global_position).normalized()
		velocity.x = direccion.x * velocidad
		
		# Voltear el sprite según la dirección
		if direccion.x != 0:
			sprite.flip_h = direccion.x < 0
	else:
		velocity.x = 0
	
	# Aplicar gravedad simple
	if not is_on_floor():
		velocity.y += 980 * delta
	else:
		velocity.y = 0
	
	move_and_slide()

func recibir_danio(cantidad: float) -> void:
	salud_actual -= cantidad
	
	# Efecto de parpadeo rojo
	modulate = Color(1.5, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	modulate = Color(1, 1, 1)
	
	if salud_actual <= 0:
		morir()

func morir() -> void:
	# Aquí puedes agregar:
	# - Animación de muerte
	# - Sonido
	# - Partículas
	# - Drop de objetos
	
	# Desactivar colisiones para que no siga haciendo daño
	set_physics_process(false)
	if area_dano:
		area_dano.set_deferred("monitoring", false)
	
	queue_free()

func _on_area_dano_body_entered(body: Node2D) -> void:
	if not puede_hacer_dano:
		return
	
	if body.is_in_group("jugadores") and body.has_method("recibir_danio"):
		body.recibir_danio(dano_contacto)
		
		# Cooldown para no hacer daño continuamente
		puede_hacer_dano = false
		await get_tree().create_timer(0.8).timeout
		puede_hacer_dano = true

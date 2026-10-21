extends CharacterBody2D

# --- Estadísticas ---
@export var salud_maxima: float = 50.0
var salud_actual: float = 50.0

@export var velocidad: float = 90.0
@export var dano_contacto: float = 15.0
@export var distancia_deteccion: float = 350.0

# --- Referencias ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_dano: Area2D = $AreaDano

var jugador: Node2D = null
var puede_hacer_dano: bool = true
var color_original: Color = Color(1, 0.2, 0.2, 1)  # Rojo permanente

func _ready() -> void:
	add_to_group("enemigos")
	salud_actual = salud_maxima
	modulate = color_original
	
	if area_dano:
		area_dano.body_entered.connect(_on_area_dano_body_entered)
		# Aseguramos que detecte al jugador
		area_dano.collision_mask = 1
		area_dano.monitoring = true

func _physics_process(delta: float) -> void:
	if jugador == null:
		var jugadores = get_tree().get_nodes_in_group("jugadores")
		if jugadores.size() > 0:
			jugador = jugadores[0]
	
	if jugador == null:
		return
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	if distancia <= distancia_deteccion:
		var direccion = (jugador.global_position - global_position).normalized()
		velocity.x = direccion.x * velocidad
		
		if direccion.x != 0 and sprite:
			sprite.flip_h = direccion.x < 0
	else:
		velocity.x = 0
	
	# Gravedad
	if not is_on_floor():
		velocity.y += 980 * delta
	else:
		velocity.y = 0
	
	move_and_slide()

func recibir_danio(cantidad: float) -> void:
	salud_actual -= cantidad
	
	# Parpadeo al recibir daño
	modulate = Color(3, 3, 3, 1)
	await get_tree().create_timer(0.1).timeout
	modulate = color_original
	
	if salud_actual <= 0:
		morir()

func morir() -> void:
	set_physics_process(false)
	if area_dano:
		area_dano.set_deferred("monitoring", false)
	queue_free()

func _on_area_dano_body_entered(body: Node2D) -> void:
	if not puede_hacer_dano:
		return
	
	if body.is_in_group("jugadores") and body.has_method("recibir_danio"):
		body.recibir_danio(dano_contacto)
		print("¡Enemigo atacó! Vida del jugador: ", body.salud_actual)  # Para depurar
		
		puede_hacer_dano = false
		await get_tree().create_timer(0.7).timeout
		puede_hacer_dano = true

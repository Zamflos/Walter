extends CharacterBody2D

@export_group("Estadísticas")
@export var vida: float = 200.0
@export var dano_ataque: float = 20.0
@export var velocidad: float = 120.0
@export var distancia_parada: float = 150.0

# Marca esta casilla en el Inspector si notas que mira al lado contrario al jugador
@export var invertir_mirada: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var zona_dano: Area2D = $ZonaDano
@onready var colision_dano: CollisionShape2D = $ZonaDano/CollisionShape2D

var lista_ataques: Array[String] = ["ataque", "giro"]
var indice_ataque: int = 0

var jugador: Node2D = null
var esta_atacando: bool = false
var ya_golpeo_en_este_ataque: bool = false

func _ready() -> void:
	colision_dano.disabled = true
	anim.play("idle")
	jugador = get_tree().get_first_node_in_group("jugadores")
	if jugador:
		add_collision_exception_with(jugador)

func _physics_process(_delta: float) -> void:
	if not jugador:
		jugador = get_tree().get_first_node_in_group("jugadores")
		return

	var direccion = global_position.direction_to(jugador.global_position)
	
	# Voltea al jefe hacia el jugador (siempre que no esté en medio de un golpe)
	if not esta_atacando and abs(direccion.x) > 0.05:
		var mirar_izquierda = direccion.x < 0
		if invertir_mirada:
			mirar_izquierda = not mirar_izquierda
			
		anim.flip_h = mirar_izquierda
		# También voltea la ZonaDano hacia donde mira el jefe
		zona_dano.scale.x = -abs(zona_dano.scale.x) if mirar_izquierda else abs(zona_dano.scale.x)

	if esta_atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distancia = global_position.distance_to(jugador.global_position)

	if distancia > distancia_parada:
		velocity = direccion * velocidad
		if anim.animation != "mover":
			anim.play("mover")
	else:
		velocity = Vector2.ZERO
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()

func _on_timer_timeout() -> void:
	if esta_atacando or not jugador:
		return

	esta_atacando = true
	ya_golpeo_en_este_ataque = false

	var ataque_actual = lista_ataques[indice_ataque]
	anim.play(ataque_actual)
	indice_ataque = (indice_ataque + 1) % lista_ataques.size()

func _on_animated_sprite_2d_frame_changed() -> void:
	if anim.animation == "ataque":
		var ultimo_frame = anim.sprite_frames.get_frame_count("ataque") - 1
		colision_dano.disabled = (anim.frame != ultimo_frame)
	elif anim.animation == "giro":
		colision_dano.disabled = not (anim.frame in [2, 3, 4])
	else:
		colision_dano.disabled = true

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation in lista_ataques:
		colision_dano.disabled = true
		esta_atacando = false
		anim.play("idle")

func _on_zona_dano_body_entered(body: Node2D) -> void:
	if ya_golpeo_en_este_ataque:
		return

	if body.is_in_group("jugadores") and body.has_method("recibir_danio"):
		body.recibir_danio(dano_ataque, global_position)
		ya_golpeo_en_este_ataque = true

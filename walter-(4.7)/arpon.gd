extends Area2D

# Dirección que le pasa el jugador
var direccion: Vector2 = Vector2.RIGHT

@export var velocidad: float = 450.0
@export var dano: float = 20.0
@export var tiempo_de_vida: float = 1.5   # segundos hasta que desaparece solo

@onready var sprite: Sprite2D = $Sprite2D   # Cambia el nombre si tu nodo se llama diferente
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Rotar el sprite según la dirección
	if direccion.x < 0:
		scale.x = -1   # Voltear horizontalmente si va a la izquierda
	
	# Conectar la señal de colisión
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Destruirse automáticamente después de un tiempo
	await get_tree().create_timer(tiempo_de_vida).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta

func _on_body_entered(body: Node2D) -> void:
	# Si choca con un enemigo
	if body.is_in_group("enemigos"):
		if body.has_method("recibir_danio"):
			body.recibir_danio(dano)
		queue_free()   # Destruir el arpón al impactar
	
	# Si choca con el suelo o paredes (opcional)
	elif body is StaticBody2D or body is TileMap:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Por si tus enemigos usan Area2D en vez de CharacterBody2D
	if area.is_in_group("enemigos"):
		if area.has_method("recibir_danio"):
			area.recibir_danio(dano)
		queue_free()

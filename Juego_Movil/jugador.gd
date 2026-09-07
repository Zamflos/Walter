extends CharacterBody2D

@export var velocidad: float = 200.0
@export var fuerza_salto: float = -350.0
@export var gravedad: float = 980.0

func _physics_process(delta: float) -> void:
	# Aplica la gravedad si el personaje está en el aire
	if not is_on_floor():
		velocity.y += gravedad * delta

	# Salto o impulso hacia arriba
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = fuerza_salto

	# Movimiento izquierda / derecha
	var direccion := Input.get_axis("mover_izquierda", "mover_derecha")
	if direccion != 0:
		velocity.x = direccion * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)

	move_and_slide()

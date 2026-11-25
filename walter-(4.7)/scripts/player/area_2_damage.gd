extends Area2D
# Zona de daño: pinchos, fuego, ácido, etc.
# Ponlo directamente en el Area2D (por ejemplo "Area2Damage").
# El Area2D necesita un CollisionShape2D o CollisionPolygon2D como hijo.

@export var dano: float = 20.0

func _physics_process(_delta: float) -> void:
	# Daña mientras el jugador esté tocando la zona.
	# La invulnerabilidad del jugador evita que pierda toda la vida de golpe.
	for body in get_overlapping_bodies():
		if body.is_in_group("jugadores") and body.has_method("recibir_danio"):
			body.recibir_danio(dano, global_position)

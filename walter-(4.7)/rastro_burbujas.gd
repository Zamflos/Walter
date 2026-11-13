extends CPUParticles2D
# Hijo del Jugador. Deja un rastro de burbujas al moverte.

@export var velocidad_minima: float = 200.0     # desde qué velocidad salen burbujas
@export var cantidad: int = 26                  # más = rastro más denso
@export var vida: float = 0.9                   # segundos que dura cada burbuja (menos = revientan antes)
@export var ascenso: float = 150.0              # qué tan rápido suben
@export var tamano_min: float = 0.15
@export var tamano_max: float = 0.45
@export var color_burbuja: Color = Color(0.75, 0.95, 1.0, 0.9)
@export var detras_del_jugador: bool = true

var _padre: CharacterBody2D

func _ready() -> void:
	_padre = get_parent() as CharacterBody2D

	emitting = false
	local_coords = false          # las burbujas se quedan en el mundo, no siguen al jugador
	show_behind_parent = detras_del_jugador
	texture = _crear_textura()

	amount = cantidad
	lifetime = vida
	lifetime_randomness = 0.6     # unas revientan antes que otras

	emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 35.0

	direction = Vector2.UP
	spread = 40.0
	initial_velocity_min = 20.0
	initial_velocity_max = 70.0
	gravity = Vector2(0.0, -ascenso)
	damping_min = 30.0
	damping_max = 70.0

	scale_amount_min = tamano_min
	scale_amount_max = tamano_max
	scale_amount_curve = _curva_reventon()

	color = color_burbuja
	color_ramp = _rampa_alfa()

func _physics_process(_delta: float) -> void:
	if _padre == null:
		return
	emitting = _padre.velocity.length() > velocidad_minima

# Burbuja hueca: centro casi transparente y borde brillante
func _crear_textura() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 0.85, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.06),
		Color(1, 1, 1, 0.10),
		Color(1, 1, 1, 0.85),
		Color(1, 1, 1, 0.0)
	])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t

# Crece un poco al nacer y se infla de golpe al final (el "pop")
func _curva_reventon() -> Curve:
	var c := Curve.new()
	c.min_value = 0.0
	c.max_value = 2.0
	c.add_point(Vector2(0.0, 0.5))
	c.add_point(Vector2(0.15, 1.0))
	c.add_point(Vector2(0.8, 1.0))
	c.add_point(Vector2(1.0, 1.5))
	return c

# Aparece rápido y se desvanece al final
func _rampa_alfa() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.1, 0.75, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.8),
		Color(1, 1, 1, 0.0)
	])
	return g

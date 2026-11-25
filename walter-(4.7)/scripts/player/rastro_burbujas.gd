extends GPUParticles2D
# Hijo del Jugador. Deja un rastro de burbujas al moverte usando la GPU.

@export var velocidad_minima: float = 200.0
@export var cantidad: int = 26
@export var vida: float = 0.9
@export var ascenso: float = 150.0
@export var tamano_min: float = 0.15
@export var tamano_max: float = 0.45
@export var color_burbuja: Color = Color(0.75, 0.95, 1.0, 0.9)
@export var detras_del_jugador: bool = true

var _padre: CharacterBody2D
var _velocidad_min_sq: float

func _ready() -> void:
	_padre = get_parent() as CharacterBody2D
	_velocidad_min_sq = velocidad_minima * velocidad_minima

	emitting = false
	local_coords = false
	show_behind_parent = detras_del_jugador
	fixed_fps = 30 # Reduce el cálculo a 30 FPS sin perder fluidez visual
	texture = _crear_textura()

	amount = cantidad
	lifetime = vida
	randomness = 0.6

	# En GPUParticles2D toda la física va dentro de ParticleProcessMaterial
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 70.0

	mat.direction = Vector3(0.0, -1.0, 0.0)
	mat.spread = 40.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0.0, -ascenso, 0.0)
	mat.damping_min = 30.0
	mat.damping_max = 70.0

	mat.scale_min = tamano_min
	mat.scale_max = tamano_max
	mat.scale_curve = _curva_reventon()

	mat.color = color_burbuja
	mat.color_ramp = _rampa_alfa()

	process_material = mat

func _physics_process(_delta: float) -> void:
	if _padre == null:
		return
	# length_squared() evita calcular raíces cuadradas cada fotograma
	emitting = _padre.velocity.length_squared() > _velocidad_min_sq

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
	t.width = 32 # 32x32 es más ligero en móvil e idéntico al escalar a 0.15-0.45
	t.height = 32
	return t

func _curva_reventon() -> CurveTexture:
	var c := Curve.new()
	c.min_value = 0.0
	c.max_value = 2.0
	c.add_point(Vector2(0.0, 0.5))
	c.add_point(Vector2(0.15, 1.0))
	c.add_point(Vector2(0.8, 1.0))
	c.add_point(Vector2(1.0, 1.5))
	
	var ct := CurveTexture.new()
	ct.curve = c
	return ct

func _rampa_alfa() -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.1, 0.75, 1.0])
	g.colors = PackedColorArray([
		Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.8),
		Color(1, 1, 1, 0.0)
	])
	
	var gt := GradientTexture1D.new()
	gt.gradient = g
	return gt

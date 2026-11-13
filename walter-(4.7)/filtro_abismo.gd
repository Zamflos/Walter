extends ColorRect
# Ponlo en el ColorRect que tiene el shader agua_abismo.gdshader.

@export var jugador: Node2D
@export var y_superficie: float = 0.0       # Y del mundo donde la profundidad es 0 (luz)
@export var y_abismo: float = 12000.0       # Y del mundo donde la profundidad es 1 (oscuridad total)
@export var suavizado_profundidad: float = 2.0

var profundidad_actual: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if jugador == null:
		return
	var mat := material as ShaderMaterial
	if mat == null:
		return

	# Posición del jugador en UV de pantalla (para la luz a su alrededor)
	var vp := get_viewport()
	var pos_pantalla: Vector2 = vp.get_canvas_transform() * jugador.global_position
	mat.set_shader_parameter("posicion_jugador", pos_pantalla / vp.get_visible_rect().size)

	# Cámara: las burbujas viven en el mundo, no en la pantalla
	var ct: Transform2D = vp.get_canvas_transform()
	mat.set_shader_parameter("offset_camara", ct.affine_inverse().origin)
	mat.set_shader_parameter("zoom_camara", ct.get_scale().x)
	mat.set_shader_parameter("tamano_viewport", vp.get_visible_rect().size)

	# Profundidad según la altura del jugador, con transición suave
	var objetivo: float = clampf(inverse_lerp(y_superficie, y_abismo, jugador.global_position.y), 0.0, 1.0)
	profundidad_actual = lerpf(profundidad_actual, objetivo, 1.0 - exp(-suavizado_profundidad * delta))
	mat.set_shader_parameter("profundidad", profundidad_actual)

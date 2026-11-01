extends CharacterBody2D

# --- Referencias a los nodos de animación ---
@onready var sprite_walk: AnimatedSprite2D = $animatedwalk
@onready var sprite_standing: AnimatedSprite2D = $animatedstanding
# --- Para disparo ---
@onready var punto_disparo: Marker2D = $PuntoDisparo
# --- Gancho (opcional: si no existe el nodo, el juego funciona igual) ---
@onready var gancho: Node = get_node_or_null("Gancho")
@export var rapidez_gancho: float = 2500.0
@export var distancia_llegada_gancho: float = 90.0
@export_range(0.0, 1.5) var impulso_al_soltar: float = 1.0  # cuánta velocidad conservas al soltarte (propulsión)
@export var duracion_impulso: float = 0.4      # tiempo que dura el vuelo antes de recuperar el control normal
@export var control_en_impulso: float = 7000.0 # qué tanto puedes desviar el vuelo con A/D
var tiempo_impulso: float = 0.0
var tiempo_atascado: float = 0.0

# --- Columpio (mantener presionado el gancho) ---
@export var gravedad_columpio: float = 3000.0     # qué tan fuerte cae al columpiarse
@export var fuerza_columpio: float = 2000.0       # qué tanto te impulsas con A/D
@export var velocidad_max_columpio: float = 2200.0
@export var jalon_inicial: float = 3000.0          # cuánto te jala el brazo al engancharte (solo una vez)
@export var rapidez_jalon_inicial: float = 2500.0 # qué tan rápido es ese primer jalón
@export var largo_minimo_columpio: float = 300.0  # el jalón nunca te deja más cerca que esto del arpón
var jalon_pendiente: float = 0.0
@export var rapidez_ajuste_cuerda: float = 1200.0 # W acorta, S alarga
var largo_cuerda: float = 0.0
var modo_columpio: bool = false
var enganche_iniciado: bool = false

# --- Movimiento ---
@export var velocidad_movimiento: float = 1200.0
@export var multiplicador_aire: float = 1.25   # más rapidez horizontal en el aire = saltos más largos

# --- Salto (se define por altura y tiempo; la gravedad se calcula sola) ---
@export var altura_salto: float = 420.0        # qué tan alto sube (en píxeles)
@export var tiempo_subida: float = 0.34        # segundos en llegar arriba (menos = menos flotante)
@export var tiempo_caida: float = 0.28         # segundos en caer desde lo más alto
@export var caida_maxima: float = 3500.0       # límite de velocidad al caer
@export_range(0.0, 1.0) var corte_salto: float = 0.25  # al soltar salto, cuánto se conserva de la subida
@export var tiempo_coyote: float = 0.1
@export var tiempo_buffer_salto: float = 0.12

# --- Doble salto ---
@export var doble_salto_activo: bool = true
@export var altura_doble_salto: float = 420.0

# --- Pared (aferrarse, deslizar y saltar) ---
@export var pared_activa: bool = true
@export var velocidad_deslizar_pared: float = 300.0
@export var impulso_salto_pared: float = 1800.0
@export var bloqueo_control_salto_pared: float = 0.12
var en_pared: bool = false
var lado_pared: float = 0.0   # dirección para alejarse de la pared (1 o -1)

# --- Dash (8 direcciones) ---
@export var rapidez_dash: float = 3500.0
@export var tiempo_dash: float = 0.16
@export var recarga_dash: float = 0.4
var esta_haciendo_dash: bool = false
var direccion_dash: Vector2 = Vector2.RIGHT

# --- Daño (retroceso e invulnerabilidad) ---
@export var tiempo_invulnerable: float = 1.0
@export var fuerza_retroceso: Vector2 = Vector2(1200.0, -700.0)
@export var duracion_retroceso: float = 0.15
var invulnerable: bool = false

# --- Salud y Vidas ---
@export var salud_maxima: float = 100.0
var salud_actual: float = 100.0
@export var tanques_reserva: int = 3

# --- Energía (Barra de Bilis) ---
@export var bilis_maxima: float = 100.0
var bilis_actual: float = 0.0
@export var ganancia_bilis_por_golpe: float = 15.0
@export var costo_curacion: float = 30.0
@export var curacion_cantidad: float = 25.0

# --- Arpón ---
@export var arpon_scene: PackedScene

# --- Valores calculados del salto ---
var vel_salto: float
var vel_doble_salto: float
var grav_subida: float
var grav_caida: float

# --- Estado interno ---
var mirando: float = 1.0
var contador_coyote: float = 0.0
var contador_buffer: float = 0.0
var saltos_extra: int = 0
var dash_aereo_disponible: bool = true
var tiempo_dash_restante: float = 0.0
var tiempo_recarga_dash: float = 0.0
var tiempo_retroceso: float = 0.0
var tiempo_bloqueo_control: float = 0.0

# Signals
signal salud_cambiada(salud, tanques)
signal bilis_cambiada(nuevo_valor)
signal inventario_alternado()

func _ready() -> void:
	# Añadir al grupo para que los enemigos puedan encontrarlo
	add_to_group("jugadores")
	configurar_controles()
	calcular_salto()

	salud_actual = salud_maxima
	salud_cambiada.emit(salud_actual, tanques_reserva)
	bilis_cambiada.emit(bilis_actual)

# Salto con Espacio o W. W va en una acción aparte ("saltar_alterno")
# para que en el gancho W sirva para subir sin soltarte.
# Las flechas ↑/↓ apuntan el dash sin hacerte saltar.
func configurar_controles() -> void:
	if not InputMap.has_action("saltar"):
		InputMap.add_action("saltar")
	for evento in InputMap.action_get_events("saltar"):
		if evento is InputEventKey and (evento.keycode == KEY_W or evento.physical_keycode == KEY_W):
			InputMap.action_erase_event("saltar", evento)

	agregar_tecla("saltar", KEY_SPACE)
	agregar_tecla("saltar_alterno", KEY_W)
	agregar_tecla("mover_arriba", KEY_W)
	agregar_tecla("mover_arriba", KEY_UP)
	agregar_tecla("mover_abajo", KEY_S)
	agregar_tecla("mover_abajo", KEY_DOWN)

func agregar_tecla(accion: String, tecla: Key) -> void:
	if not InputMap.has_action(accion):
		InputMap.add_action(accion)
	for evento in InputMap.action_get_events(accion):
		if evento is InputEventKey and (evento.keycode == tecla or evento.physical_keycode == tecla):
			return
	var nuevo := InputEventKey.new()
	nuevo.physical_keycode = tecla
	InputMap.action_add_event(accion, nuevo)

# Convierte altura y tiempos en velocidad de salto y gravedad
func calcular_salto() -> void:
	grav_subida = 2.0 * altura_salto / (tiempo_subida * tiempo_subida)
	grav_caida = 2.0 * altura_salto / (tiempo_caida * tiempo_caida)
	vel_salto = -2.0 * altura_salto / tiempo_subida
	vel_doble_salto = -sqrt(2.0 * grav_subida * altura_doble_salto)

func _physics_process(delta: float) -> void:
	var direccion: float = Input.get_axis("mover_izquierda", "mover_derecha")

	if tiempo_recarga_dash > 0.0:
		tiempo_recarga_dash -= delta

	# --- Durante el dash: recto en la dirección elegida, sin gravedad ---
	if esta_haciendo_dash:
		tiempo_dash_restante -= delta
		velocity = direccion_dash * rapidez_dash
		move_and_slide()
		var choco: bool = (is_on_wall() and absf(direccion_dash.x) > 0.7) \
				or (is_on_ceiling() and direccion_dash.y < -0.7) \
				or (is_on_floor() and direccion_dash.y > 0.7)
		if tiempo_dash_restante <= 0.0 or choco:
			terminar_dash()
		actualizaranimacion(mirando)
		return

	# --- Durante el retroceso por daño: sin control ---
	if tiempo_retroceso > 0.0:
		tiempo_retroceso -= delta
		velocity.y = min(velocity.y + grav_caida * delta, caida_maxima)
		move_and_slide()
		actualizaranimacion(0.0)
		return

	# --- Jalado por el gancho ---
	if gancho and gancho.esta_enganchado():
		tirar_hacia_gancho(delta)
		return
	enganche_iniciado = false

	# --- Suelo / Gravedad ---
	if is_on_floor():
		contador_coyote = tiempo_coyote
		recargar_habilidades_aereas()
	else:
		contador_coyote -= delta
		var g: float = grav_subida if velocity.y < 0.0 else grav_caida
		velocity.y = min(velocity.y + g * delta, caida_maxima)

	# --- Pegado a la pared: cae lento ---
	if en_pared:
		if direccion != 0.0 and signf(direccion) == lado_pared:
			en_pared = false   # presionar hacia afuera suelta la pared
		else:
			velocity.y = min(velocity.y, velocidad_deslizar_pared)
			velocity.x = -lado_pared * 50.0
			mirando = lado_pared

	# --- Salto (Espacio): buffer, coyote, pared y doble salto ---
	if salto_presionado():
		contador_buffer = tiempo_buffer_salto
	else:
		contador_buffer -= delta

	if contador_buffer > 0.0:
		if en_pared:
			salto_pared()
		elif contador_coyote > 0.0:
			saltar(vel_salto)
		elif saltos_extra > 0:
			saltos_extra -= 1
			saltar(vel_doble_salto)

	# Salto variable: al soltar el botón deja de subir
	if salto_soltado() and velocity.y < 0.0:
		velocity.y *= corte_salto

	# --- Movimiento horizontal instantáneo; más rápido en el aire ---
	if is_on_floor():
		tiempo_impulso = 0.0   # al tocar el suelo se acaba el vuelo del arpón

	if tiempo_bloqueo_control > 0.0:
		tiempo_bloqueo_control -= delta
	elif not en_pared:
		var rapidez: float = velocidad_movimiento
		if not is_on_floor():
			rapidez *= multiplicador_aire
		var objetivo: float = direccion * rapidez
		if tiempo_impulso > 0.0:
			# Volando por el arpón: conserva el impulso y solo se desvía poco a poco
			tiempo_impulso -= delta
			velocity.x = move_toward(velocity.x, objetivo, control_en_impulso * delta)
		else:
			velocity.x = objetivo
		if direccion != 0.0:
			mirando = signf(direccion)

	move_and_slide()

	actualizar_pared(direccion)

	# --- Control de Animación ---
	actualizaranimacion(0.0 if en_pared else direccion)

	# --- Acciones y Habilidades ---

	# Dash (Shift Izq) en 8 direcciones con WASD
	if Input.is_action_just_pressed("dash") and tiempo_recarga_dash <= 0.0 \
			and (is_on_floor() or en_pared or dash_aereo_disponible):
		ejecutar_dash()

	# Ataque con Arpón (Clic Izquierdo)
	if Input.is_action_just_pressed("atacar"):
		atacar()

	# Curación (Tecla F)
	if Input.is_action_just_pressed("curar"):
		intentar_curacion()

	# Abrir/Cerrar Inventario (Tecla Tab)
	if Input.is_action_just_pressed("inventario"):
		inventario_alternado.emit()

func tirar_hacia_gancho(delta: float) -> void:
	en_pared = false
	var hacia: Vector2 = gancho.punto_enganche - global_position

	# Primer cuadro enganchado: decide el modo.
	# Botón mantenido = columpio. Un toque rápido = jalón directo.
	if not enganche_iniciado:
		enganche_iniciado = true
		modo_columpio = Input.is_action_pressed("gancho")
		largo_cuerda = hacia.length()
		jalon_pendiente = jalon_inicial

	# Cancelar con salto o con dash (en ambos modos)
	if Input.is_action_just_pressed("saltar"):
		soltar_gancho()
		saltar(vel_salto * 0.8)
		return
	if Input.is_action_just_pressed("dash") and tiempo_recarga_dash <= 0.0:
		soltar_gancho()
		ejecutar_dash()
		return

	if modo_columpio:
		# Soltar el botón = sales volando con la velocidad del columpio
		if not Input.is_action_pressed("gancho"):
			soltar_gancho()
			actualizaranimacion(mirando)
			return
		columpiarse(delta)
		return

	# --- Modo jalón directo ---
	# Llegó al gancho: sale disparado con la velocidad que traía
	if hacia.length() <= distancia_llegada_gancho:
		soltar_gancho()
		actualizaranimacion(0.0)
		return

	velocity = hacia.normalized() * rapidez_gancho
	if velocity.x != 0.0:
		mirando = signf(velocity.x)

	var antes: Vector2 = global_position
	move_and_slide()
	# Si algo lo bloquea en el camino un momento, se suelta
	if global_position.distance_to(antes) < rapidez_gancho * delta * 0.2:
		tiempo_atascado += delta
		if tiempo_atascado > 0.08:
			soltar_gancho()
	else:
		tiempo_atascado = 0.0

	actualizaranimacion(mirando)

func columpiarse(delta: float) -> void:
	var ancla: Vector2 = gancho.punto_enganche

	# Gravedad: es lo que hace que el columpio baje y suba
	velocity.y += gravedad_columpio * delta

	# A/D empujan para tomar vuelo
	var empuje: float = Input.get_axis("mover_izquierda", "mover_derecha")
	velocity.x += empuje * fuerza_columpio * delta
	velocity = velocity.limit_length(velocidad_max_columpio)

	# W acorta la cuerda (subes), S la alarga (bajas)
	var ajuste: float = Input.get_axis("mover_arriba", "mover_abajo")
	# Jalón solo al engancharte; después el brazo solo cambia con W/S
	var recoger: float = 0.0
	if jalon_pendiente > 0.0:
		recoger = minf(rapidez_jalon_inicial * delta, jalon_pendiente)
		# No te acerca más del largo mínimo, para que quede espacio para columpiarte
		recoger = minf(recoger, maxf(largo_cuerda - largo_minimo_columpio, 0.0))
		jalon_pendiente -= recoger
		if recoger <= 0.0:
			jalon_pendiente = 0.0
	largo_cuerda += ajuste * rapidez_ajuste_cuerda * delta - recoger
	largo_cuerda = clampf(largo_cuerda, distancia_llegada_gancho, gancho.alcance_maximo)

	move_and_slide()

	# La cuerda no se estira: si te pasas del largo, te regresa al círculo
	var desde_ancla: Vector2 = global_position - ancla
	var distancia: float = desde_ancla.length()
	if distancia > largo_cuerda and distancia > 0.0:
		var normal: Vector2 = desde_ancla / distancia
		move_and_collide(ancla + normal * largo_cuerda - global_position)
		# Quita la velocidad que te aleja del ancla; queda solo el balanceo
		var hacia_afuera: float = velocity.dot(normal)
		if hacia_afuera > 0.0:
			velocity -= normal * hacia_afuera

	if absf(velocity.x) > 50.0:
		mirando = signf(velocity.x)
	actualizaranimacion(0.0)

func soltar_gancho() -> void:
	enganche_iniciado = false
	gancho.soltar()                # el brazo regresa a su lugar
	velocity *= impulso_al_soltar  # sales disparado con la velocidad del jalón
	tiempo_impulso = duracion_impulso
	tiempo_atascado = 0.0
	recargar_habilidades_aereas()

func salto_presionado() -> bool:
	return Input.is_action_just_pressed("saltar") or Input.is_action_just_pressed("saltar_alterno")

# Cuenta como "soltar el salto" solo si ya no tienes presionada ninguna de las dos teclas
func salto_soltado() -> bool:
	var solto: bool = Input.is_action_just_released("saltar") or Input.is_action_just_released("saltar_alterno")
	var sigue: bool = Input.is_action_pressed("saltar") or Input.is_action_pressed("saltar_alterno")
	return solto and not sigue

func recargar_habilidades_aereas() -> void:
	dash_aereo_disponible = true
	saltos_extra = 1 if doble_salto_activo else 0

func saltar(fuerza: float) -> void:
	velocity.y = fuerza
	contador_buffer = 0.0
	contador_coyote = 0.0

func actualizar_pared(dir: float) -> void:
	if not pared_activa or is_on_floor() or not is_on_wall():
		en_pared = false
		return

	if en_pared:
		return

	var normal_x: float = signf(get_wall_normal().x)
	var presiona_hacia_pared: bool = dir != 0.0 and signf(dir) == -normal_x
	if presiona_hacia_pared and velocity.y >= 0.0:
		en_pared = true
		lado_pared = normal_x
		tiempo_bloqueo_control = 0.0
		recargar_habilidades_aereas()

func salto_pared() -> void:
	en_pared = false
	velocity.y = vel_salto * 0.9
	var dir: float = Input.get_axis("mover_izquierda", "mover_derecha")

	if dir != 0.0 and signf(dir) == lado_pared:
		# Hacia afuera: salto largo alejándote de la pared
		velocity.x = lado_pared * impulso_salto_pared
		mirando = lado_pared
		tiempo_bloqueo_control = bloqueo_control_salto_pared
	elif dir != 0.0:
		# Hacia la pared: subes pegado a ella (para escalar)
		velocity.x = 0.0
		mirando = -lado_pared
		tiempo_bloqueo_control = 0.0
	else:
		# Sin dirección: subes casi recto, despegándote apenas
		velocity.x = lado_pared * impulso_salto_pared * 0.3
		mirando = lado_pared
		tiempo_bloqueo_control = 0.06

	contador_buffer = 0.0
	contador_coyote = 0.0

func actualizaranimacion(dir: float) -> void:
	if sprite_walk == null or sprite_standing == null:
		return

	sprite_walk.flip_h = mirando < 0.0
	sprite_standing.flip_h = mirando < 0.0
	punto_disparo.position.x = abs(punto_disparo.position.x) * mirando

	if dir != 0.0:
		sprite_standing.visible = false
		sprite_standing.stop()
		sprite_walk.visible = true
		sprite_walk.play("walk")
	else:
		sprite_walk.visible = false
		sprite_walk.stop()
		sprite_standing.visible = true
		sprite_standing.play("standing")

func ejecutar_dash() -> void:
	var dir: Vector2 = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")

	if en_pared:
		# Desde la pared nunca se dashea hacia la pared
		if dir.x == 0.0 or signf(dir.x) == -lado_pared:
			dir.x = lado_pared
		en_pared = false

	if dir == Vector2.ZERO:
		dir = Vector2(mirando, 0.0)

	# En el suelo, un dash hacia abajo se vuelve horizontal
	if is_on_floor() and dir.y > 0.0:
		dir.y = 0.0
		if dir.x == 0.0:
			dir.x = mirando

	direccion_dash = dir.normalized()
	if direccion_dash.x != 0.0:
		mirando = signf(direccion_dash.x)

	esta_haciendo_dash = true
	tiempo_dash_restante = tiempo_dash
	if not is_on_floor():
		dash_aereo_disponible = false

	# Flash del dash
	modulate = Color(0.6, 1.2, 1.5)

func terminar_dash() -> void:
	esta_haciendo_dash = false
	tiempo_recarga_dash = recarga_dash
	velocity *= 0.25   # frena al terminar para que no salga disparado
	modulate = Color(1, 1, 1)

func atacar() -> void:
	if arpon_scene == null:
		push_warning("No se ha asignado la escena del arpón (arpon_scene)")
		return

	var arpon = arpon_scene.instantiate()
	arpon.direccion = (get_global_mouse_position() - punto_disparo.global_position).normalized()
	arpon.global_position = punto_disparo.global_position
	get_parent().add_child(arpon)
	mirando = -1.0 if get_global_mouse_position().x < global_position.x else 1.0
	recuperar_bilis(ganancia_bilis_por_golpe)

	# Flash visual rápido
	modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.07).timeout
	modulate = Color(1, 1, 1)

func recuperar_bilis(cantidad: float) -> void:
	bilis_actual = clamp(bilis_actual + cantidad, 0.0, bilis_maxima)
	bilis_cambiada.emit(bilis_actual)

func intentar_curacion() -> void:
	if bilis_actual >= costo_curacion and salud_actual < salud_maxima:
		bilis_actual -= costo_curacion
		curar(curacion_cantidad)
		bilis_cambiada.emit(bilis_actual)

# origen: posición de lo que hizo daño (para saber hacia dónde empujar)
func recibir_danio(cantidad: float, origen: Vector2 = Vector2.INF) -> void:
	if invulnerable:
		return

	salud_actual -= cantidad
	if salud_actual <= 0:
		if tanques_reserva > 0:
			tanques_reserva -= 1
			salud_actual = salud_maxima
		else:
			morir()
			return
	salud_cambiada.emit(salud_actual, tanques_reserva)

	if esta_haciendo_dash:
		terminar_dash()
	if gancho:
		gancho.soltar()
	en_pared = false
	var lado: float = -mirando
	if origen != Vector2.INF and global_position.x != origen.x:
		lado = signf(global_position.x - origen.x)
	velocity = Vector2(lado * fuerza_retroceso.x, fuerza_retroceso.y)
	tiempo_retroceso = duracion_retroceso

	activar_invulnerabilidad()

func activar_invulnerabilidad() -> void:
	invulnerable = true
	var parpadeos: int = int(tiempo_invulnerable / 0.1)
	for i in parpadeos:
		modulate.a = 0.3 if i % 2 == 0 else 1.0
		await get_tree().create_timer(0.1).timeout
	modulate.a = 1.0
	invulnerable = false

func curar(cantidad: float) -> void:
	salud_actual = clamp(salud_actual + cantidad, 0.0, salud_maxima)
	salud_cambiada.emit(salud_actual, tanques_reserva)

func morir() -> void:
	get_tree().reload_current_scene()

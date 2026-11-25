extends Control

@export var es_movimiento: bool = true
@export var es_apuntado: bool = false

@export var deadzone: float = 0.25
@export var max_distance: float = 80.0

@onready var base: TextureRect = $Base
@onready var stick: TextureRect = $Stick

var touching := false
var touch_index := -1
var direction := Vector2.ZERO
var was_aiming := false   # para saber si había apuntado antes de soltar

signal disparar_arpón(direccion: Vector2)   # se emite al soltar el stick de apuntado

func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	mouse_filter = Control.MOUSE_FILTER_STOP
	if stick:
		stick.position = (size - stick.size) / 2.0

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag and touching and event.index == touch_index:
		_update_stick(event.position)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if touching:
			return
		var local := get_global_transform_with_canvas().affine_inverse() * event.position
		if not Rect2(Vector2.ZERO, size).has_point(local):
			return
		touching = true
		touch_index = event.index
		was_aiming = false
		_update_stick(event.position)
	else:
		if event.index == touch_index:
			_release()

func _update_stick(global_pos: Vector2) -> void:
	var center := global_position + size / 2.0
	var offset := global_pos - center

	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance

	stick.position = (size - stick.size) / 2.0 + offset

	var strength := offset.length() / max_distance
	if strength < deadzone:
		direction = Vector2.ZERO
	else:
		direction = offset.normalized() * ((strength - deadzone) / (1.0 - deadzone))
		was_aiming = true

	if es_movimiento:
		_simular_movimiento()

func _release() -> void:
	# Si es el joystick de apuntado y había apuntado, disparamos
	if es_apuntado and was_aiming and direction.length() > 0.1:
		disparar_arpón.emit(direction.normalized())

	touching = false
	touch_index = -1
	direction = Vector2.ZERO
	was_aiming = false
	stick.position = (size - stick.size) / 2.0

	if es_movimiento:
		_soltar_movimiento()

func _simular_movimiento() -> void:
	if direction.x < -deadzone:
		Input.action_press("mover_izquierda")
		Input.action_release("mover_derecha")
	elif direction.x > deadzone:
		Input.action_press("mover_derecha")
		Input.action_release("mover_izquierda")
	else:
		Input.action_release("mover_izquierda")
		Input.action_release("mover_derecha")

func _soltar_movimiento() -> void:
	Input.action_release("mover_izquierda")
	Input.action_release("mover_derecha")

func get_direction() -> Vector2:
	return direction

func is_aiming() -> bool:
	return direction.length() > 0.1

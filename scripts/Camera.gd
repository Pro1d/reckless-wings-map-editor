extends Camera

enum CameraAction { ROTATE, MOVE, NONE }
enum AnchorMode { LOCAL, GLOBAL, CAMERA }
enum AnchorFallback { NULL, CAMERA, MAX }

class Anchor:
	var position : Vector3
	var normal : Vector3
	func _init(p : Vector3, n : Vector3):
		position = p
		normal = n

signal rotating(is_rotating)
signal moving(is_moving, horizontal_anchor)

export(float, EXP) var anchor_max_range := 1024.0
export var zoom_step := 1.1
export(float, EXP) var zoom_min_range := 10.0 # distance to the anchor point
export var rotate_speed := (2 * PI)
export(float, EXP) var navigable_sphere_radius := 2048.0
export(AnchorMode) var rotating_anchor_mode := AnchorMode.GLOBAL
export(AnchorMode) var moving_anchor_mode := AnchorMode.CAMERA

var action : int = CameraAction.NONE
var tool_valid := false
var tool_position : Vector3
var tool_normal : Vector3
var anchor : Anchor
var saved_mouse_position : Vector2

onready var default_transform := global_transform

func get_anchor_point(screen_pos : Vector2, fallback := AnchorFallback.NULL) -> Anchor:
	if tool_valid:
		return Anchor.new(tool_position, tool_normal)
	match fallback:
		AnchorFallback.CAMERA:
			return Anchor.new(global_transform.origin, Vector3.UP)
		AnchorFallback.MAX:
			var from := project_ray_origin(screen_pos)
			var direction := project_ray_normal(screen_pos)
			var ray_length := anchor_max_range if direction.y >= 0 \
				else min((0.0 - from.y) / direction.y, anchor_max_range)
			var to := from + direction * ray_length
			return Anchor.new(to, Vector3.UP)
		AnchorFallback.NULL, _:
			return null

func apply_zoom(factor : float):
	var current_pos := global_transform.origin
	var anchor_direction := current_pos.direction_to(anchor.position)
	var anchor_distance := current_pos.distance_to(anchor.position)
	if factor < 1.0:
		anchor_distance = clamp(anchor_distance, zoom_min_range, anchor_max_range)
	else:
		if anchor_distance > anchor_max_range:
			anchor_distance = anchor_max_range
		elif anchor_distance * (1 / factor) < zoom_min_range:
			factor = 1.0
	global_translate(anchor_direction * anchor_distance * (1 - 1 / factor))

func start_move(event : InputEvent) -> void:
	if not event.control and not event.alt and event.shift:
		moving_anchor_mode = AnchorMode.GLOBAL
	else:
		moving_anchor_mode = AnchorMode.CAMERA
	anchor = get_anchor_point(event.position, AnchorFallback.NULL)
	
	if anchor != null:
		action = CameraAction.MOVE
		Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		emit_signal("moving", true, moving_anchor_mode == AnchorMode.GLOBAL)

func apply_move(screen_pos : Vector2) -> bool:
	var normal := Vector3.UP # AnchorMode.GLOBAL
	match moving_anchor_mode:
		AnchorMode.CAMERA:
			normal = global_transform.basis * Vector3.FORWARD
		AnchorMode.LOCAL:
			normal = anchor.normal
	var ray := project_ray_normal(screen_pos)
	if abs(ray.dot(normal)) < cos(deg2rad(80)):
		return false
	var plane := Plane(normal, normal.dot(anchor.position))
	var intersection_point := plane.intersects_ray(global_transform.origin, ray)
	if intersection_point == null:
		return false
	global_translate(anchor.position - intersection_point)
	return true

func end_move() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	action = CameraAction.NONE
	emit_signal("moving", false, false)

func start_rotate(event : InputEvent) -> void:
	if not event.control and not event.alt and event.shift:
		anchor = Anchor.new(global_transform.origin, Vector3.UP)
		rotating_anchor_mode = AnchorMode.CAMERA
	else:
		anchor = get_anchor_point(event.position, AnchorFallback.NULL)
		rotating_anchor_mode = AnchorMode.LOCAL

	if anchor != null:
		action = CameraAction.ROTATE
		saved_mouse_position = event.global_position
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		emit_signal("rotating", true)

func apply_rotate(screen_delta : Vector2):
	var use_anchor : bool = rotating_anchor_mode == AnchorMode.LOCAL
	var delta_sign := -1.0 if use_anchor else 1.0
	var delta_scale := rotate_speed / max(get_viewport().size.x, get_viewport().size.y)
	var rot_y_global := screen_delta.x * delta_scale * delta_sign
	var rot_x_local := screen_delta.y * delta_scale * delta_sign
	var current_angle := global_transform.basis.get_euler()
	current_angle.x = clamp(current_angle.x + rot_x_local, -0.95 * PI / 2, 0.95 * PI / 2)
	current_angle.y = current_angle.y + rot_y_global
	current_angle.z = 0
	var local_center := to_local(anchor.position)
	if use_anchor:
		translate(local_center)
	global_transform.basis = Basis(current_angle)
	if use_anchor:
		translate(-local_center)

func end_rotate() -> void:
	action = CameraAction.NONE
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.warp_mouse_position(saved_mouse_position)
	emit_signal("rotating", false)

func clamp_position():
	var position := global_transform.origin
	position.y = max(position.y, near * 1.732)
	var dist := position.length()
	if dist > navigable_sphere_radius:
		position *= navigable_sphere_radius / dist
	global_transform.origin = position

func new_action_allowed() -> bool:
	return action == CameraAction.NONE

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if not (event.control or event.alt):
			if e.button_index == BUTTON_RIGHT:
				if e.pressed:
					if new_action_allowed():
						start_rotate(event)
				else:
					if action == CameraAction.ROTATE:
						end_rotate()
			elif e.button_index == BUTTON_MIDDLE:
				if e.pressed:
					if new_action_allowed():
						start_move(event)
				else:
					if action == CameraAction.MOVE:
						end_move()
			elif e.button_index == BUTTON_WHEEL_DOWN:
				if new_action_allowed():
					anchor = get_anchor_point(event.position, AnchorFallback.MAX)
					apply_zoom(1.0 / zoom_step)
					clamp_position()
			elif e.button_index == BUTTON_WHEEL_UP:
				if new_action_allowed():
					anchor = get_anchor_point(event.position, AnchorFallback.MAX)
					apply_zoom(zoom_step)
					clamp_position()
	elif event is InputEventMouseMotion:
		match action:
			CameraAction.NONE:
				pass
			CameraAction.MOVE:
				var e := event as InputEventMouseMotion
				var _done := apply_move(e.position)
				clamp_position()
			CameraAction.ROTATE:
				var e := event as InputEventMouseMotion
				apply_rotate(e.relative)
				clamp_position()

func _on_tool_position_changed(position, normal):
	tool_position = position
	tool_normal = normal
	tool_valid = true

func _on_tool_position_invalid():
	tool_valid = false

func _on_HUD_reset_camera_triggered():
	global_transform = default_transform

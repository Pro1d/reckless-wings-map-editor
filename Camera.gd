extends Camera

enum CameraAction { ROTATE, MOVE, NONE }


export var anchor_max_range := 512.0
export var zoom_step := 1.1
export var zoom_min_range := 5.0 # distance to the anchor point
export var rotate_speed := (2 * PI)
export var navigable_box := AABB(Vector3(1, 0, 1) * -1024.0, Vector3.ONE * 2048.0)
var action : int = CameraAction.NONE
var anchor_point := Vector3.ZERO
var anchor_normal := Vector3.UP
var saved_mouse_position := Vector2.ZERO
onready var anchor_visual := get_parent().get_node("ToolTangent") as ToolVisual

class AnchorResult:
	var position : Vector3
	var normal : Vector3
	func _init(p : Vector3, n : Vector3):
		position = p
		normal = n

func get_anchor_point(screen_pos : Vector2, fallback_origin := false) -> AnchorResult:
	var from := project_ray_origin(screen_pos)
	var direction := project_ray_normal(screen_pos)
	var ray_length := anchor_max_range if direction.y >= 0 \
		else min((0.0 - from.y) / direction.y, anchor_max_range)
	var to := from + direction * ray_length
	var hit := get_world().direct_space_state.intersect_ray(from, to)
	if hit.empty(): # TODO handle case diffrently for zoom and move/rotate
		if fallback_origin:
			return AnchorResult.new(global_transform.origin, Vector3.UP)
		else:
			return AnchorResult.new(to, Vector3.UP)
	else:
		return AnchorResult.new(hit["position"] as Vector3, hit["normal"] as Vector3)

func apply_zoom(anchor_point : Vector3, factor : float):
	var current_pos := global_transform.origin
	var anchor_distance := max(current_pos.distance_to(anchor_point), zoom_min_range)
	if anchor_distance * factor > anchor_max_range:
		pass #factor = anchor_max_range / anchor_distance
	elif anchor_distance * factor < zoom_min_range:
		factor = max(factor, 1.0)
	global_translate((anchor_point - current_pos) * (1 - factor))

func apply_move(anchor_point : Vector3, screen_pos : Vector2) -> bool:
	var ray := project_ray_normal(screen_pos)
	if abs(ray.y) < 0.01:
		return false
	# intersection ray / plane{y=anchor.y}
	var y_plane := anchor_point.y
	var current_pos := global_transform.origin
	var distance := (y_plane - current_pos.y) / ray.y
	if distance < 0.01:
		return false
	var factor := 1.0 if distance < anchor_max_range else anchor_max_range / distance
	var intersection_point := current_pos + ray * distance
	var motion := (anchor_point - intersection_point) * factor
	global_translate(motion)
	return true
	
func apply_rotate(anchor_point : Vector3, screen_delta : Vector2):
	var use_anchor := true
	var delta_sign := -1.0 if use_anchor else 1.0
	var delta_scale := rotate_speed / max(get_viewport().size.x, get_viewport().size.y)
	var rot_y_global := screen_delta.x * delta_scale * delta_sign
	var rot_x_local := screen_delta.y * delta_scale * delta_sign
	var current_angle := global_transform.basis.get_euler()
	current_angle.x = clamp(current_angle.x + rot_x_local, -0.95 * PI / 2, 0.95 * PI / 2)
	current_angle.y = current_angle.y + rot_y_global
	current_angle.z = 0
	var local_center := to_local(anchor_point)
	if use_anchor:
		translate(local_center)
	global_transform.basis = Basis(current_angle)
	if use_anchor:
		translate(-local_center)

func clamp_position():
	var position := global_transform.origin
	position.x = clamp(position.x, navigable_box.position.x, navigable_box.end.x)
	position.y = clamp(position.y, navigable_box.position.y, navigable_box.end.y)
	position.z = clamp(position.z, navigable_box.position.z, navigable_box.end.z)
	global_transform.origin = position

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if not (event.shift or event.control or event.alt):
			if e.button_index == BUTTON_RIGHT:
				if not e.pressed:
					action = CameraAction.NONE
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					Input.warp_mouse_position(saved_mouse_position)
				else:
					var p := get_anchor_point(event.position, true)
					action = CameraAction.ROTATE
					anchor_point = p.position
					anchor_normal = p.normal
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					saved_mouse_position = event.global_position
			elif e.button_index == BUTTON_MIDDLE:
				if not e.pressed:
					action = CameraAction.NONE
					Input.set_default_cursor_shape(Input.CURSOR_ARROW)
				else:
					var p := get_anchor_point(event.position, false)
					action = CameraAction.MOVE
					anchor_point = p.position
					anchor_normal = p.normal
					Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			elif e.button_index == BUTTON_WHEEL_DOWN:
				var p := get_anchor_point(event.position, false).position if action == CameraAction.NONE else anchor_point
				apply_zoom(p, zoom_step)
				clamp_position()
			elif e.button_index == BUTTON_WHEEL_UP:
				var p := get_anchor_point(event.position, false).position if action == CameraAction.NONE else anchor_point
				apply_zoom(p, 1.0 / zoom_step)
				clamp_position()
			update_anchor_visual()
	elif event is InputEventMouseMotion:
		match action:
			CameraAction.NONE:
				pass
			CameraAction.MOVE:
				var e := event as InputEventMouseMotion
				if not apply_move(anchor_point, e.position):
					pass #action = CameraAction.NONE
				else:
					clamp_position()
			CameraAction.ROTATE:
				var e := event as InputEventMouseMotion
				apply_rotate(anchor_point, e.relative)
				clamp_position()
		if action == CameraAction.NONE:
			var p := get_anchor_point(event.position, false)
			anchor_point = p.position
			anchor_normal = p.normal
		update_anchor_visual()

func update_anchor_visual():
	#if action == CameraAction.NONE:
	#	anchor_visual.hide()
	#else:
	#	anchor_visual.show()
	anchor_visual.set_tool_position(anchor_point, anchor_normal)

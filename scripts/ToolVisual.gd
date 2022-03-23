class_name ToolVisual
extends MeshInstance

var radius : float setget set_radius
var tool_valid := false
var tool_position : Vector3
var tool_normal : Vector3
var position_locked := false

func shader() -> ShaderMaterial:
	return get_active_material(0) as ShaderMaterial

func set_radius(r : float) -> void:
	radius = r
	shader().set_shader_param("outter_ring_radius", radius)

func update_tool_position() -> void:
	if tool_valid:
		show()
		if tool_normal.cross(Vector3.UP).length() < sin(deg2rad(1)):
			global_transform.basis = Basis(Vector3(PI / 2, 0, 0))
		else:
			global_transform.basis = Transform().looking_at(tool_normal, Vector3.UP).basis
		global_transform.origin = tool_position
	else:
		hide()

func _on_HUD_tool_radius_changed(r : float):
	set_radius(r)

func _on_tool_position_changed(position : Vector3, normal : Vector3):
	tool_valid = true
	tool_position = position
	tool_normal = normal
	if not position_locked:
		update_tool_position()

func _on_tool_position_invalid():
	tool_valid = false
	if not position_locked:
		update_tool_position()

func set_lock_position(lock : bool) -> void:
	position_locked = lock
	if not lock:
		update_tool_position()

func _on_camera_moving(is_moving : bool, horizontal_anchor : bool):
	var billboard := is_moving and not horizontal_anchor
	var shape_mode := 1 if is_moving else 0
	if is_moving and horizontal_anchor:
		tool_normal = Vector3.UP
		update_tool_position()
	shader().set_shader_param("billboard", billboard)
	shader().set_shader_param("shape_mode", shape_mode)
	set_lock_position(is_moving)

func _on_camera_rotating(is_rotating : bool):
	var billboard := is_rotating
	var shape_mode := 2 if is_rotating else 0
	shader().set_shader_param("billboard", billboard)
	shader().set_shader_param("shape_mode", shape_mode)
	set_lock_position(is_rotating)

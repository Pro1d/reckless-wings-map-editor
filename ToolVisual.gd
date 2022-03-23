class_name ToolVisual
extends MeshInstance

const max_radius := 30.0
var radius := 10.0 setget set_radius

func _ready():
	self.radius = 15.0

func set_radius(r : float) -> void:
	radius = r
	var mat := get_active_material(0) as ShaderMaterial
	mat.set_shader_param("outter_ring_radius", radius)

func set_tool_position(origin : Vector3, normal : Vector3) -> void:
	if abs(normal.dot(Vector3.UP)) > 0.999:
		global_transform.basis = Basis()
		global_transform.origin = origin
	else:
		var t := Transform().looking_at(normal, Vector3.UP) * Transform().rotated(Vector3.LEFT, PI/2)
		t.origin = origin
		global_transform = t

func _input(event : InputEvent):
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.control:
			if e.button_index == BUTTON_WHEEL_DOWN:
				self.radius = clamp(radius - 1.0, 1.0, max_radius)
			elif e.button_index == BUTTON_WHEEL_UP:
				self.radius = clamp(radius + 1.0, 1.0, max_radius)


func _on_HUD_tool_radius_changed(radius):
	set_radius(radius)

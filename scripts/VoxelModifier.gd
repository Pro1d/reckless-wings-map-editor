extends VoxelLodTerrain

const ToolType = preload("res://scripts/ToolType.gd")

signal tool_position_changed(position, normal)
signal tool_position_invalid()

class RaycastResult:
	var position : Vector3
	var normal : Vector3
	func _init(p : Vector3, n : Vector3):
		position = p
		normal = n

export(float, EXP) var max_edition_distance := 1024.0
const edition_time_step := 1.0 / 60

var raycast_result : RaycastResult
var raycast_dirty := true
var camera_active := false
var tool_active := false
var tool_reversed := false # TODO from hud: toggle tool on control pressed/released
var tool_type := ToolType.BURRY
var tool_radius : float
var tool_weight : float
var edition_elapsed := 0.0
onready var voxel_scale := global_transform.basis.get_scale().x;
onready var voxel_z := global_transform.origin.z;
onready var camera := get_parent().get_node("Camera") as Camera
onready var voxel_tool := get_voxel_tool() as VoxelToolLodTerrain
onready var screen_pos := get_viewport().get_mouse_position()

func _ready():
	var s := VoxelStreamRegionFiles.new()
	s.directory = "res://saves/"
	s.save_generator_output = true
	s.lod_count = lod_count
	stream = s

func _exit_tree():
	save_modified_blocks()

func _process(delta):
	edition_elapsed += delta

	if raycast_dirty:
		raycast_result = screen_raycast(screen_pos)
		raycast_dirty = false
		if raycast_result != null:
			var position := to_global(raycast_result.position)
			var normal := global_transform.basis.xform(raycast_result.normal).normalized()
			emit_signal("tool_position_changed", position, normal)
		else:
			emit_signal("tool_position_invalid")

	if tool_active and raycast_result != null and edition_elapsed >= edition_time_step:
		edition_elapsed = 0.0 if edition_elapsed > 2 * edition_time_step else edition_elapsed - edition_time_step
		voxel_tool.edition_speed = tool_weight
		voxel_tool.crease_noise_period = 1.0 * voxel_scale
		voxel_tool.edition_normal = raycast_result.normal
		match tool_type:
			ToolType.BURRY:
				voxel_tool.mode = VoxelTool.MODE_ADD if not tool_reversed else VoxelTool.MODE_REMOVE
			ToolType.DIG:
				voxel_tool.mode = VoxelTool.MODE_REMOVE if not tool_reversed else VoxelTool.MODE_ADD
			ToolType.SMOOTH:
				voxel_tool.mode = VoxelTool.MODE_SMOOTH if not tool_reversed else VoxelTool.MODE_CREASE
			ToolType.CREASE:
				voxel_tool.mode = VoxelTool.MODE_CREASE if not tool_reversed else VoxelTool.MODE_SMOOTH
			ToolType.PLANE:
				voxel_tool.mode = VoxelTool.MODE_PLANE

		voxel_tool.do_sphere(raycast_result.position, tool_radius / voxel_scale)
		raycast_dirty = true

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		if not camera_active:
			var e := event as InputEventMouseButton
			if e.button_index == BUTTON_LEFT:
				if not e.pressed:
					tool_active = false
				else:
					tool_active = true
					tool_reversed = event.control
	if event is InputEventMouseMotion:
		raycast_dirty = true
		screen_pos = event.position

func screen_raycast(pos2 : Vector2) -> RaycastResult:
	var origin := to_local(camera.global_transform.origin) #to_local(camera.project_ray_origin(screen_pos))
	var direction := global_transform.basis.xform_inv(camera.project_ray_normal(pos2))
	direction = direction.normalized()
	var dist_max := max_edition_distance / voxel_scale
	var result := voxel_tool.raycast(origin, direction, dist_max)
	if result != null and result.distance < dist_max: # and result.distance > 2.0
		return RaycastResult.new(origin + direction * result.distance, result.normal)
	else:
		var dist_to_bottom := (voxel_z / voxel_scale + 0.1 - origin.y) / direction.y
		var position := origin + dist_to_bottom * direction
		if dist_to_bottom > 0 and voxel_bounds.has_point(position):
			return RaycastResult.new(position, Vector3.UP)
		else:
			return null

func _on_HUD_tool_radius_changed(radius):
	tool_radius = radius

func _on_HUD_tool_type_changed(type):
	tool_type = type

func _on_HUD_tool_weight_changed(weight):
	tool_weight = weight

func _on_camera_moving(is_moving):
	camera_active = is_moving
	if camera_active:
		tool_active = false
	else:
		raycast_dirty = true

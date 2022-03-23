extends VoxelLodTerrain

const ToolType = preload("res://scripts/ToolType.gd")

var screen_pos := Vector2(0, 0)
var tool_active := false
var tool_reversed := false # TODO from hud: toggle tool on control pressed/released
var tool_type := ToolType.BURRY
var tool_radius : float
var tool_weight : float
const max_edition_distance := 1024.0
onready var voxel_scale := global_transform.basis.get_scale().x;

func _process(delta):
	if tool_active:
		var camera := get_parent().get_node("Camera") as Camera
		var voxel_tool := get_voxel_tool()
		#voxel_tool.set_raycast_binary_search_iterations(8)
		voxel_tool.sdf_scale = tool_weight
		match tool_type:
			ToolType.BURRY:
				voxel_tool.mode = VoxelTool.MODE_ADD if not tool_reversed else VoxelTool.MODE_REMOVE
			ToolType.DIG:
				voxel_tool.mode = VoxelTool.MODE_REMOVE if not tool_reversed else VoxelTool.MODE_ADD
			ToolType.SMOOTH:
				voxel_tool.mode = VoxelTool.MODE_SET
		var origin := to_local(camera.project_ray_origin(screen_pos))
		var direction = global_transform.basis.xform_inv(camera.project_ray_normal(screen_pos))
		direction = direction.normalized()
		var dist_max := max_edition_distance / voxel_scale
		var result := voxel_tool.raycast(origin, direction, dist_max)
		if result != null and result.distance < dist_max:
			voxel_tool.do_sphere(result.get_position(), tool_radius / voxel_scale)

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == BUTTON_LEFT:
			if not e.pressed:
				tool_active = false
			else:
				tool_active = true
				tool_reversed = event.control
		screen_pos = e.position
	if event is InputEventMouseMotion:
		screen_pos = event.position


func _on_HUD_tool_radius_changed(radius):
	tool_radius = radius

func _on_HUD_tool_type_changed(type):
	tool_type = type

func _on_HUD_tool_weight_changed(weight):
	tool_weight = weight

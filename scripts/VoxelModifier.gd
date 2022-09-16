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

var constraint_enabled := false
var constraint_plane : Plane
var raycast_result : RaycastResult
var raycast_dirty := true
var camera_active := false
var tool_active := false
var tool_reversed := false # TODO from hud: toggle tool on control pressed/released
var tool_type := ToolType.BURRY
var tool_radius : float
var tool_weight : float
var tool_texture_index : int
var edition_elapsed := 0.0
onready var voxel_scale := global_transform.basis.get_scale().x;
onready var voxel_z := global_transform.origin.z;
onready var camera := get_parent().get_node("Camera") as Camera
onready var voxel_tool := get_voxel_tool() as VoxelToolLodTerrain
onready var screen_pos := get_viewport().get_mouse_position()

func _enter_tree():
	var s := VoxelStreamRegionFiles.new()
	s.directory = "res://saves2/"
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
				voxel_tool.mode = VoxelTool.MODE_PLANE if not tool_reversed else VoxelTool.MODE_LEVEL
			ToolType.LEVEL:
				voxel_tool.mode = VoxelTool.MODE_LEVEL if not tool_reversed else VoxelTool.MODE_PLANE
			ToolType.PAINT:
				voxel_tool.mode = VoxelTool.MODE_TEXTURE_PAINT
				voxel_tool.texture_index = tool_texture_index
				voxel_tool.texture_opacity = tool_weight
				voxel_tool.texture_falloff = 0.25

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
	elif event is InputEventMouseMotion:
		raycast_dirty = true
		screen_pos = event.position
	elif event is InputEventKey:
		var e := event as InputEventKey
		match e.physical_scancode:
			KEY_CONTROL:
				if e.pressed:
					if raycast_result != null:
						constraint_enabled = true
						constraint_plane = Plane(
							raycast_result.normal,
							raycast_result.normal.dot(raycast_result.position))
				else:
					constraint_enabled = false
					raycast_dirty = true

func screen_raycast(pos2 : Vector2) -> RaycastResult:
	var origin := to_local(camera.global_transform.origin) #to_local(camera.project_ray_origin(screen_pos))
	var direction := global_transform.basis.xform_inv(camera.project_ray_normal(pos2))
	direction = direction.normalized()
	var dist_max := max_edition_distance / voxel_scale

	if constraint_enabled:
		var result := constraint_plane.intersects_ray(origin, direction)
		if result != null and origin.distance_to(result) < dist_max:
			return RaycastResult.new(result, constraint_plane.normal)
		else:
			return null
	else:
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

func _on_HUD_tool_texture_index_changed(index):
	tool_texture_index = index

func _on_camera_moving(is_moving : bool, _horizontal_anchor := false):
	camera_active = is_moving
	if camera_active:
		tool_active = false
	else:
		raycast_dirty = true

func prop_print(obj):
	var list = obj.get_property_list()
	for elt in list:
		print ("[", elt["class_name"], "] ", elt["name"], " = ", var2str(obj.get(elt["name"])))

func get_noise_data(osn : OpenSimplexNoise):
	var data := {}
	for key in ["seed", "octaves", "period", "persistence", "lacunarity"]:
		data[key] = var2str(osn.get(key))
	return data
func get_fast_noise_data(fnl : FastNoiseLite):
	var data := var2str(fnl)
	#prop_print(fnl)
	#prop_print(str2var(data))
	#for key in ["seed", "octaves", "period", "persistence", "lacunarity"]:
	#	data[key] = var2str(fnl.get(key))
	return data

func get_curve_data(c : Curve):
	prop_print(c)
	prop_print(str2var(var2str(c)))
	var data := {}
	for key in ["min_value", "max_value", "bake_resolution", "_data"]:
		data[key] = var2str(c.get(key))
	return data

func get_save_data():
	var s = var2str(self)
	for i in range(int(len(s) / 50)):
		print(s.substr(i*50, 50))
	return var2bytes(self) # unset material? unset ...?
	var data := {}
	#prop_print(self)
	assert(generator.voxel_scale == scale.x)
	assert(generator.voxel_scale == scale.y)
	assert(generator.voxel_scale == scale.z)
	assert(generator.sea_height == -translation.y)
	data["scale"] = var2str(scale)
	data["translation"] = var2str(translation)
	data["view_distance"] = var2str(view_distance)
	data["voxel_bounds"] = var2str(voxel_bounds)
	data["lod_count"] = var2str(lod_count)
	data["lod_distance"] = var2str(lod_distance)
	data["generator"] = {
		"voxel_scale": generator.voxel_scale,
		"sea_height": generator.sea_height,
		"max_height": generator.max_height,
		"radius": generator.radius,
		"radius_cutoff_power": generator.radius_cutoff_power,
		"radius_cutoff_scale": generator.radius_cutoff_scale,
		"ground_ratio": generator.ground_ratio,
		"biome_transition": generator.biome_transition,
		"biome_noise": get_noise_data(generator.biome_noise),
		"height_noise": get_noise_data(generator.height_noise),
		"curve_biome0": get_curve_data(generator.curve_biome0),
		"curve_biome1": get_curve_data(generator.curve_biome1),
		"cliff_noise": get_noise_data(generator.cliff_noise),
		"cliff_noise_factor": generator.cliff_noise_factor,
	}
	data["instancer"] = []
	for prop in $VoxelInstancer.library.get_property_list():
		if prop["class_name"] == "VoxelInstanceLibraryItemBase":
			var item = $VoxelInstancer.library.get(prop["name"])
			#prop_print(item)
			#print('- -')
			#prop_print(item.generator)
			data["instancer"].append({
				# mesh, mesh_lod1, mesh_lod2, mesh_lod3, collision_shapes
				"cast_shadow": var2str(item.cast_shadow),
				"collision_layer": var2str(item.collision_layer),
				"collision_mask": var2str(item.collision_mask),
				"generator": {
					"density": var2str(item.generator.density),
					"emit_mode": var2str(item.generator.emit_mode),
					"min_slope_degrees": var2str(item.generator.min_slope_degrees),
					"min_height": var2str(item.generator.min_height),
					"max_height": var2str(item.generator.max_height),
					"min_scale": var2str(item.generator.min_scale),
					"max_scale": var2str(item.generator.max_scale),
					"scale_distribution": var2str(item.generator.scale_distribution),
					"vertical_alignment": var2str(item.generator.vertical_alignment),
					"random_vertical_flip": var2str(item.generator.random_vertical_flip),
					"random_rotation": var2str(item.generator.random_rotation),
					"offset_along_normal": var2str(item.generator.offset_along_normal),
					"noise": get_fast_noise_data(item.generator.noise),
					"noise_dimension": var2str(item.generator.noise_dimension),
					"noise_on_scale": var2str(item.generator.noise_on_scale),
				},
			})
	#print(get_noise_data(generator.biome_noise))
	#print(get_curve_data(generator.curve_biome0))
	#prop_print(generator)
	return data

func _on_HUD_save_map(map_name):
	get_save_data()


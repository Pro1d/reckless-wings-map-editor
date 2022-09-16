extends Control

const ToolType = preload("res://scripts/ToolType.gd")

signal tool_type_changed(type)
signal tool_radius_changed(radius)
signal tool_weight_changed(weight)
signal reset_camera_triggered()
signal save_map(map_name)

var tool_type := ToolType.BURRY setget set_tool_type
var tool_radius : float = 0.0 setget set_tool_radius
var tool_weight : float = 0.0 setget set_tool_weight

onready var button_burry := $CenterContainer/PanelContainer/Tools/ButtonBurry
onready var button_dig := $CenterContainer/PanelContainer/Tools/ButtonDig
onready var button_level := $CenterContainer/PanelContainer/Tools/ButtonLevel
onready var button_plane := $CenterContainer/PanelContainer/Tools/ButtonPlane
onready var button_smooth := $CenterContainer/PanelContainer/Tools/ButtonSmooth
onready var button_crease := $CenterContainer/PanelContainer/Tools/ButtonCrease
onready var button_paint := $CenterContainer/PanelContainer/Tools/ButtonPaint
onready var slider_radius := $CenterContainer/PanelContainer/Tools/VBoxContainerRadius/SliderRadius
onready var slider_weight := $CenterContainer/PanelContainer/Tools/VBoxContainerWeight/SliderWeight
onready var button_reset_camera := $CenterContainer/PanelContainer/Tools/ButtonResetCamera
onready var button_save := $CenterContainer/PanelContainer/Tools/ButtonSave

func _ready():
	var _e := OK # enum Error
	_e = button_burry.connect("pressed", self, "_button_burry")
	_e = button_dig.connect("pressed", self, "_button_dig")
	_e = button_level.connect("pressed", self, "_button_level")
	_e = button_plane.connect("pressed", self, "_button_plane")
	_e = button_smooth.connect("pressed", self, "_button_smooth")
	_e = button_crease.connect("pressed", self, "_button_crease")
	_e = button_paint.connect("pressed", self, "_button_paint")
	_e = slider_radius.connect("value_changed", self, "set_tool_radius")
	_e = slider_weight.connect("value_changed", self, "set_tool_weight")
	_e = button_reset_camera.connect("pressed", self, "_button_reset_camera")
	_e = button_save.connect("pressed", self, "_button_save")
	set_default_tool()

func _unhandled_input(event : InputEvent):
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.control and not e.shift and not e.alt:
			if e.button_index == BUTTON_WHEEL_DOWN:
				slider_radius.value = tool_radius - 1
			elif e.button_index == BUTTON_WHEEL_UP:
				slider_radius.value = tool_radius + 1

func set_default_tool() -> void:
	self.tool_type = ToolType.BURRY
	slider_radius.value = 20.0
	slider_weight.value = 0.5

func set_tool_type(type) -> void:
	tool_type = type
	button_burry.set_pressed_no_signal(type == ToolType.BURRY)
	button_dig.set_pressed_no_signal(type == ToolType.DIG)
	button_level.set_pressed_no_signal(type == ToolType.LEVEL)
	button_plane.set_pressed_no_signal(type == ToolType.PLANE)
	button_smooth.set_pressed_no_signal(type == ToolType.SMOOTH)
	button_crease.set_pressed_no_signal(type == ToolType.CREASE)
	button_paint.set_pressed_no_signal(type == ToolType.PAINT)
	emit_signal("tool_type_changed", type)

func set_tool_radius(radius : float) -> void:
	tool_radius = radius
	$CenterContainer/PanelContainer/Tools/VBoxContainerRadius/LabelRadius.text = "Radius: "+str(radius)+"m"
	emit_signal("tool_radius_changed", radius)

func set_tool_weight(weight : float) -> void:
	tool_weight = weight
	$CenterContainer/PanelContainer/Tools/VBoxContainerWeight/LabelWeight.text = "Weight: "+str(round(weight * 100))+"%"
	emit_signal("tool_weight_changed", weight)

func _button_burry():
	self.tool_type = ToolType.BURRY
func _button_dig():
	self.tool_type = ToolType.DIG
func _button_level():
	self.tool_type = ToolType.LEVEL
func _button_plane():
	self.tool_type = ToolType.PLANE
func _button_smooth():
	self.tool_type = ToolType.SMOOTH
func _button_crease():
	self.tool_type = ToolType.CREASE
func _button_paint():
	self.tool_type = ToolType.PAINT
func _button_reset_camera():
	emit_signal("reset_camera_triggered")
func _button_save():
	emit_signal("save_map", "latest")

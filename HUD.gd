extends Control

const ToolType = preload("res://scripts/ToolType.gd")

signal tool_type_changed(type)
signal tool_radius_changed(radius)
signal tool_weight_changed(weight)

var tool_type := ToolType.BURRY setget set_tool_type
var tool_radius : float setget set_tool_radius
var tool_weight : float setget set_tool_weight

# Called when the node enters the scene tree for the first time.
func _ready():
	$CenterContainer/Tools/ButtonBurry.connect("pressed", self, "_button_burry")
	$CenterContainer/Tools/ButtonDig.connect("pressed", self, "_button_dig")
	$CenterContainer/Tools/ButtonSmooth.connect("pressed", self, "_button_smooth")
	$CenterContainer/Tools/VBoxContainerRadius/SliderRadius.connect("value_changed", self, "set_tool_radius")
	$CenterContainer/Tools/VBoxContainerWeight/SliderWeight.connect("value_changed", self, "set_tool_weight")
	set_default_tool()

func set_default_tool() -> void:
	self.tool_type = ToolType.BURRY
	self.tool_radius = 10.0
	self.tool_weight = 1.0

func set_tool_type(type) -> void:
	tool_type = type
	$CenterContainer/Tools/ButtonBurry.set_pressed_no_signal(type == ToolType.BURRY)
	$CenterContainer/Tools/ButtonDig.set_pressed_no_signal(type == ToolType.DIG)
	$CenterContainer/Tools/ButtonSmooth.set_pressed_no_signal(type == ToolType.SMOOTH)
	emit_signal("tool_type_changed", type)

func set_tool_radius(radius : float) -> void:
	tool_radius = radius
	$CenterContainer/Tools/VBoxContainerRadius/LabelRadius.text = "Radius: "+str(round(radius))+"m"
	emit_signal("tool_radius_changed", radius)

func set_tool_weight(weight : float) -> void:
	tool_weight = weight
	$CenterContainer/Tools/VBoxContainerWeight/LabelWeight.text = "Weight: "+str(round(weight * 100))+"%"
	emit_signal("tool_weight_changed", weight)

func _button_burry():
	self.tool_type = ToolType.BURRY
func _button_dig():
	self.tool_type = ToolType.DIG
func _button_smooth():
	self.tool_type = ToolType.SMOOTH

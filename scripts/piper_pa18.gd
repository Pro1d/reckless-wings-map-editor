extends Spatial


func _unhandled_input(event : InputEvent):
	if event is InputEventKey:
		var e := event as InputEventKey
		if e.pressed and e.scancode == KEY_A:
			visible = not visible

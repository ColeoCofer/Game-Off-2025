extends Node

# InputModeManager - Automatically show/hide cursor based on input device
# Hides cursor when controller is used, shows when mouse is used

enum InputMode {
	KEYBOARD_MOUSE,
	CONTROLLER
}

var current_mode: InputMode = InputMode.KEYBOARD_MOUSE

func _ready() -> void:
	# Start with cursor visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	# Check for controller input
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Only switch to controller mode if there's actual input (not just noise)
		if event is InputEventJoypadMotion:
			# Ignore small deadzone movements
			if abs(event.axis_value) < 0.3:
				return

		if current_mode != InputMode.CONTROLLER:
			current_mode = InputMode.CONTROLLER
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Check for mouse/keyboard input
	elif event is InputEventMouseMotion or event is InputEventMouseButton:
		if current_mode != InputMode.KEYBOARD_MOUSE:
			current_mode = InputMode.KEYBOARD_MOUSE
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Keyboard input also shows cursor
	elif event is InputEventKey:
		if current_mode != InputMode.KEYBOARD_MOUSE:
			current_mode = InputMode.KEYBOARD_MOUSE
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

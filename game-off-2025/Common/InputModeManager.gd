extends Node

# InputModeManager - Automatically show/hide cursor based on input device
# Hides cursor when controller is used, shows when mouse is used

enum InputMode {
	KEYBOARD_MOUSE,
	CONTROLLER
}

var current_mode: InputMode = InputMode.KEYBOARD_MOUSE
var force_cursor_visible: bool = false  # For menus that need cursor always visible

func _ready() -> void:
	# Start with cursor visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_force_cursor_visible(force: bool) -> void:
	"""Force cursor to be visible (for menus) or allow normal input-based behavior"""
	force_cursor_visible = force
	if force:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Restore cursor state based on current input mode
		if current_mode == InputMode.CONTROLLER:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	# Don't change cursor mode if it's being forced visible (e.g., in menus)
	if force_cursor_visible:
		# Still track the input mode for when force is released
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			if event is InputEventJoypadMotion:
				if abs(event.axis_value) < 0.3:
					return
			current_mode = InputMode.CONTROLLER
		elif event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
			current_mode = InputMode.KEYBOARD_MOUSE
		return

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

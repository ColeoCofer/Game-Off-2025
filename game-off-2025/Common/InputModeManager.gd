extends Node

# InputModeManager - Automatically show/hide cursor based on input device
# Hides cursor when controller is used, shows when mouse is used
# Also provides UI input debouncing for analog stick navigation

enum InputMode {
	KEYBOARD_MOUSE,
	CONTROLLER
}

var current_mode: InputMode = InputMode.KEYBOARD_MOUSE
var force_cursor_visible: bool = false  # For menus that need cursor always visible

# UI input debouncing - requires stick to return to center before next input
var _ui_mode_enabled: bool = false
var _action_released: Dictionary = {}  # Tracks which actions have been released

func _ready() -> void:
	# Start with cursor visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_ui_mode(enabled: bool) -> void:
	"""Enable/disable UI input debouncing. Call with true when showing menus, false when hiding."""
	_ui_mode_enabled = enabled
	if enabled:
		# Reset all release states when entering UI mode
		_action_released.clear()

func is_ui_action_pressed(action: String, event: InputEvent) -> bool:
	"""
	Use this in menus for debounced analog stick input.
	Requires the action to be released before it can trigger again.
	Pass the current event from _input().
	"""
	if not _ui_mode_enabled:
		# Not in UI mode, use normal input
		return event.is_action_pressed(action)

	# Initialize release state if not tracked yet (default to true so first press works)
	if not _action_released.has(action):
		_action_released[action] = true

	# Check for release
	if event.is_action_released(action):
		_action_released[action] = true
		return false

	# Check for press
	if event.is_action_pressed(action):
		if _action_released[action]:
			_action_released[action] = false
			return true

	return false

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

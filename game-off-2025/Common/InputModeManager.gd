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
var _direction_held: Dictionary = {
	"up": false,
	"down": false,
	"left": false,
	"right": false
}

const STICK_DEADZONE: float = 0.5  # Higher deadzone for UI navigation
const STICK_RELEASE_THRESHOLD: float = 0.3  # Must return below this to allow next input

func _ready() -> void:
	# Start with cursor visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_ui_mode(enabled: bool) -> void:
	"""Enable/disable UI input debouncing. Call with true when showing menus, false when hiding."""
	_ui_mode_enabled = enabled
	if enabled:
		# Reset all held states when entering UI mode
		for dir in _direction_held:
			_direction_held[dir] = false

func is_ui_action_pressed(action: String, event: InputEvent) -> bool:
	"""
	Use this in menus for debounced analog stick input.
	Requires the stick to return to center before it can trigger again.
	Pass the current event from _input().
	"""
	if not _ui_mode_enabled:
		return event.is_action_pressed(action)

	# Handle analog stick input specially
	if event is InputEventJoypadMotion:
		return _handle_stick_navigation(event, action)

	# For keyboard/d-pad, use normal behavior
	return event.is_action_pressed(action)

func _handle_stick_navigation(event: InputEventJoypadMotion, action: String) -> bool:
	"""Handle analog stick with debouncing - only triggers once per push."""
	var dominated: String = ""
	var axis_value: float = event.axis_value

	# Determine direction from axis
	if event.axis == JOY_AXIS_LEFT_X:
		if axis_value < -STICK_DEADZONE:
			dominated = "left"
		elif axis_value > STICK_DEADZONE:
			dominated = "right"
		elif abs(axis_value) < STICK_RELEASE_THRESHOLD:
			# Stick returned to center - reset horizontal
			_direction_held["left"] = false
			_direction_held["right"] = false
	elif event.axis == JOY_AXIS_LEFT_Y:
		if axis_value < -STICK_DEADZONE:
			dominated = "up"
		elif axis_value > STICK_DEADZONE:
			dominated = "down"
		elif abs(axis_value) < STICK_RELEASE_THRESHOLD:
			# Stick returned to center - reset vertical
			_direction_held["up"] = false
			_direction_held["down"] = false

	if dominated == "":
		return false

	# Check if this action matches the direction
	var action_matches = false
	match dominated:
		"up": action_matches = (action == "ui_up" or action == "up")
		"down": action_matches = (action == "ui_down" or action == "down")
		"left": action_matches = (action == "ui_left" or action == "left")
		"right": action_matches = (action == "ui_right" or action == "right")

	if not action_matches:
		return false

	# Check if this direction is already held
	if _direction_held[dominated]:
		return false

	# First time pressing this direction - allow it and mark as held
	_direction_held[dominated] = true
	return true

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

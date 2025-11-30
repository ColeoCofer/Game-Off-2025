extends CanvasLayer

## Web-only fullscreen toggle button that appears in the bottom right corner

@onready var button: Button = $Button

func _ready() -> void:
	# Only show on web builds
	if OS.get_name() != "Web":
		queue_free()
		return

	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	_toggle_fullscreen()
	_update_button_text()


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _update_button_text() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		button.text = "Exit Fullscreen"
	else:
		button.text = "Fullscreen"

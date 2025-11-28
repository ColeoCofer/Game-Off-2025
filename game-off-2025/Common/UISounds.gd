extends Node

## UISounds - Global manager for UI audio feedback
## Plays sounds when navigating between UI elements and pressing buttons

var hover_sound: AudioStreamPlayer
var click_sound: AudioStreamPlayer
var _mouse_hover_enabled: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Create audio players for UI sounds
	hover_sound = AudioStreamPlayer.new()
	hover_sound.stream = preload("res://Assets/Audio/UI/UI-1.wav")
	hover_sound.bus = "Sounds"
	add_child(hover_sound)

	click_sound = AudioStreamPlayer.new()
	click_sound.stream = preload("res://Assets/Audio/UI/UI-2.wav")
	click_sound.bus = "Sounds"
	add_child(click_sound)

	# Disable mouse hover sounds until mouse moves
	_mouse_hover_enabled = false
	_last_mouse_pos = get_viewport().get_mouse_position()

	# Reset hover state on scene changes
	SceneManager.scene_changed.connect(_on_scene_changed)


func _input(event: InputEvent) -> void:
	# Enable mouse hover sounds once mouse actually moves after scene load
	if event is InputEventMouseMotion and not _mouse_hover_enabled:
		var current_pos = get_viewport().get_mouse_position()
		if current_pos.distance_to(_last_mouse_pos) > 5.0:
			_mouse_hover_enabled = true


func _on_scene_changed(_path: String) -> void:
	# Disable mouse hover until mouse moves again
	_mouse_hover_enabled = false
	# Store current mouse position to detect actual movement
	if get_viewport():
		_last_mouse_pos = get_viewport().get_mouse_position()


func play_hover() -> void:
	# Don't play hover sounds during scene transitions
	if SceneManager.is_transitioning:
		return
	# Don't play hover sound if mouse button is pressed (click will play instead)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return
	hover_sound.play()


## Called from mouse_entered signals - only plays if mouse has moved since scene load
func play_hover_mouse() -> void:
	if SceneManager.is_transitioning:
		return
	if not _mouse_hover_enabled:
		return
	# Don't play hover sound if mouse button is pressed
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return
	hover_sound.play()


func play_click() -> void:
	click_sound.play()

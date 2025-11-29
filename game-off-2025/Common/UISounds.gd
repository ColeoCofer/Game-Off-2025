extends Node

## UISounds - Global manager for UI audio feedback
## Plays hover sound when moving between buttons, click sound when pressed

var hover_sound: AudioStreamPlayer
var click_sound: AudioStreamPlayer
var _suppress_until: float = 0.0

func _ready() -> void:
	hover_sound = AudioStreamPlayer.new()
	hover_sound.stream = preload("res://Assets/Audio/UI/UI-1.wav")
	hover_sound.bus = "Sounds"
	add_child(hover_sound)

	click_sound = AudioStreamPlayer.new()
	click_sound.stream = preload("res://Assets/Audio/UI/UI-2.wav")
	click_sound.bus = "Sounds"
	add_child(click_sound)

	# Watch for scene changes to suppress hover sounds briefly
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	# When a root-level node is added (scene change), suppress hover briefly
	if node.get_parent() == get_tree().root:
		_suppress_until = Time.get_ticks_msec() + 150


func play_hover() -> void:
	# Suppress hover sounds briefly after scene loads
	if Time.get_ticks_msec() < _suppress_until:
		return
	# Don't play hover when clicking (click will play instead)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	hover_sound.play()


func play_click() -> void:
	click_sound.play()

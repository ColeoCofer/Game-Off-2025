extends Control

# Signals for dialogue events
signal dialogue_advanced  # Emitted when player advances to next line
signal text_fully_displayed  # Emitted when typewriter completes
signal dialogue_box_shown  # Emitted when box finishes appearing
signal dialogue_box_hidden  # Emitted when box finishes hiding

# Export variables for customization
@export var typing_speed: float = 30.0  # Characters per second
@export var fade_duration: float = 0.2  # Seconds for fade in/out
@export var auto_advance_delay: float = 0.0  # 0 = manual only, >0 = auto advance after delay
@export var play_text_blip: bool = true  # Play sound on each character
@export var blip_interval: int = 2  # Play blip every N characters (to avoid spam)

# Node references
@onready var character_name_label: Label = $ContentMargin/VBoxContainer/CharacterName
@onready var dialogue_text: RichTextLabel = $ContentMargin/VBoxContainer/DialogueText
@onready var continue_indicator: Label = $ContinueIndicator
@onready var typewriter_timer: Timer = $TypewriterTimer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var dialogue_audio_player: AudioStreamPlayer = $DialogueAudioPlayer
@onready var background: ColorRect = $Background
@onready var border: ColorRect = $Border
@onready var content_margin: MarginContainer = $ContentMargin

# State variables
var current_text: String = ""
var is_empty_text_mode: bool = false  # True when showing only continue indicator
var displayed_text: String = ""
var current_char_index: int = 0
var is_typing: bool = false
var can_advance: bool = false
var character_count: int = 0

func _ready():
	# Hide by default
	modulate.a = 0.0
	visible = false
	continue_indicator.visible = false

	# Set up typewriter timer
	typewriter_timer.wait_time = 1.0 / typing_speed

	# Start the continue indicator blink animation
	_start_continue_indicator_blink()

func _input(event):
	if not visible:
		return

	# Check for advance input (Space, Enter, A button on gamepad, or left mouse click)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		_handle_advance_input()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		_handle_advance_input()

func _handle_advance_input():
	if is_typing:
		# Complete the typewriter instantly
		_complete_typewriter_instantly()
	elif can_advance:
		# Advance to next dialogue
		dialogue_advanced.emit()

func show_dialogue(text: String, character_name: String = "", audio_path: String = ""):
	"""Display dialogue text with optional character name and audio.
	If text is empty (""), only shows the continue indicator without the dialogue box."""
	current_text = text
	displayed_text = ""
	current_char_index = 0
	character_count = 0
	can_advance = false
	continue_indicator.visible = false

	# Check for empty text mode - show only continue indicator
	if text == "":
		is_empty_text_mode = true
		is_typing = false
		can_advance = true

		# Hide dialogue box elements
		background.visible = false
		border.visible = false
		content_margin.visible = false

		# Show only the continue indicator
		continue_indicator.visible = true
		text_fully_displayed.emit()
		return

	# Normal dialogue mode
	is_empty_text_mode = false

	# Show dialogue box elements (in case they were hidden)
	background.visible = true
	border.visible = true
	content_margin.visible = true

	# Set character name
	if character_name != "":
		character_name_label.text = character_name
		character_name_label.visible = true
	else:
		character_name_label.visible = false

	# Play dialogue audio if provided
	# Supports multiple audio paths separated by "|" - plays them sequentially
	if audio_path != "" and dialogue_audio_player:
		if "|" in audio_path:
			# Multiple audio files - play them in sequence
			var audio_paths = audio_path.split("|")
			_play_audio_sequence(audio_paths)
		else:
			# Single audio file
			var audio_stream = load(audio_path)
			if audio_stream:
				dialogue_audio_player.stream = audio_stream
				dialogue_audio_player.play()

	# Clear the text and start typewriter
	dialogue_text.text = ""
	is_typing = true
	typewriter_timer.start()

func show_box():
	"""Fade in the dialogue box"""
	visible = true
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.finished.connect(_on_show_complete)

func show_box_empty_text_mode():
	"""Show the box instantly without fade, with elements hidden (for empty text mode).
	Only shows the continue indicator."""
	visible = true
	modulate.a = 1.0
	is_empty_text_mode = true
	background.visible = false
	border.visible = false
	content_margin.visible = false
	continue_indicator.visible = true
	can_advance = true
	is_typing = false
	dialogue_box_shown.emit()

func hide_box():
	"""Fade out the dialogue box"""
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(_on_hide_complete)

func _on_show_complete():
	dialogue_box_shown.emit()

func _on_hide_complete():
	visible = false
	dialogue_box_hidden.emit()

var _audio_stream_queue: Array = []  # Preloaded AudioStream objects

func _play_audio_sequence(audio_paths: Array) -> void:
	"""Play multiple audio files in sequence (preloads all for seamless playback)"""
	_audio_stream_queue = []

	# Preload all audio streams upfront to avoid loading delay between plays
	for path in audio_paths:
		var trimmed = path.strip_edges()
		if trimmed != "":
			var audio_stream = load(trimmed)
			if audio_stream:
				_audio_stream_queue.append(audio_stream)

	if _audio_stream_queue.is_empty():
		return

	# Connect to finished signal if not already connected
	if not dialogue_audio_player.finished.is_connected(_on_sequence_audio_finished):
		dialogue_audio_player.finished.connect(_on_sequence_audio_finished)

	# Play the first audio
	_play_next_in_sequence()

func _play_next_in_sequence() -> void:
	"""Play the next audio stream in the queue"""
	if _audio_stream_queue.is_empty():
		return

	var next_stream = _audio_stream_queue.pop_front()
	dialogue_audio_player.stream = next_stream
	dialogue_audio_player.play()

func _on_sequence_audio_finished() -> void:
	"""Called when an audio in the sequence finishes"""
	if not _audio_stream_queue.is_empty():
		_play_next_in_sequence()

func _on_typewriter_timer_timeout():
	if not is_typing:
		typewriter_timer.stop()
		return

	if current_char_index < current_text.length():
		# Add next character
		var next_char = current_text[current_char_index]
		displayed_text += next_char
		dialogue_text.text = displayed_text
		current_char_index += 1
		character_count += 1

		# Play text blip sound effect
		if play_text_blip and character_count % blip_interval == 0:
			_play_text_blip()
	else:
		# Typewriter complete
		_complete_typewriter()

func _complete_typewriter():
	"""Called when typewriter effect finishes naturally"""
	is_typing = false
	typewriter_timer.stop()
	can_advance = true
	continue_indicator.visible = true
	text_fully_displayed.emit()

	# Auto-advance if configured
	if auto_advance_delay > 0.0:
		await get_tree().create_timer(auto_advance_delay).timeout
		if can_advance:  # Check if still waiting
			dialogue_advanced.emit()

func _complete_typewriter_instantly():
	"""Force complete the typewriter effect immediately"""
	is_typing = false
	typewriter_timer.stop()
	displayed_text = current_text
	dialogue_text.text = displayed_text
	current_char_index = current_text.length()
	can_advance = true
	continue_indicator.visible = true
	text_fully_displayed.emit()

func _play_text_blip():
	"""Play a short blip sound for text typing"""
	# TODO: Load actual audio file when available
	# For now, just call play() which will play if an AudioStream is assigned
	if audio_player.stream:
		audio_player.play()

func _start_continue_indicator_blink():
	"""Animate the continue indicator with a blink effect"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(continue_indicator, "modulate:a", 0.3, 0.5)
	tween.tween_property(continue_indicator, "modulate:a", 1.0, 0.5)

func set_typing_speed(speed: float):
	"""Update typing speed (characters per second)"""
	typing_speed = speed
	typewriter_timer.wait_time = 1.0 / typing_speed

func is_text_complete() -> bool:
	"""Check if the current text has finished displaying"""
	return not is_typing and can_advance

func clear():
	"""Clear all dialogue and reset state"""
	current_text = ""
	displayed_text = ""
	dialogue_text.text = ""
	current_char_index = 0
	is_typing = false
	can_advance = false
	is_empty_text_mode = false
	continue_indicator.visible = false
	character_name_label.visible = false

	# Restore dialogue box elements visibility
	background.visible = true
	border.visible = true
	content_margin.visible = true

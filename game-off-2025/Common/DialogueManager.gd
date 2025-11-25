extends Node
## Global DialogueManager autoload singleton
## Manages dialogue sequences, DialogueBox instances, and dialogue state throughout the game

# Signals for dialogue events
signal dialogue_started  # Emitted when a dialogue sequence begins
signal dialogue_finished  # Emitted when all dialogue lines complete
signal line_changed(line_index: int)  # Emitted when displaying a new line
signal dialogue_skipped  # Emitted if dialogue is force-skipped

# Dialogue data structures
class DialogueLine:
	var text: String = ""
	var character: String = ""  # Optional character name
	var pause_duration: float = 0.0  # Auto-advance delay (0 = manual)
	var callback: Callable = Callable()  # Function to call after line displays
	var audio_path: String = ""  # Optional path to dialogue audio file

	func _init(p_text: String = "", p_character: String = "", p_pause: float = 0.0, p_callback: Callable = Callable(), p_audio_path: String = ""):
		text = p_text
		character = p_character
		pause_duration = p_pause
		callback = p_callback
		audio_path = p_audio_path

# State variables
var dialogue_box_scene: PackedScene = preload("res://UI/DialogueBox/dialogue_box.tscn")
var dialogue_box: Control = null
var canvas_layer: CanvasLayer = null

var dialogue_queue: Array[DialogueLine] = []
var current_line_index: int = -1
var is_dialogue_active: bool = false
var is_paused: bool = false

# Configuration
var dialogue_layer: int = 99  # CanvasLayer layer (below pause menu at 100)
var allow_skip: bool = true  # Allow force-skipping dialogue

func _ready():
	# Create persistent CanvasLayer for dialogue
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = dialogue_layer
	canvas_layer.name = "DialogueCanvasLayer"
	add_child(canvas_layer)

func start_dialogue(lines: Array) -> void:
	"""Start a new dialogue sequence with an array of DialogueLine objects"""
	if is_dialogue_active:
		push_warning("DialogueManager: Cannot start new dialogue while one is active")
		return

	if lines.is_empty():
		push_warning("DialogueManager: Cannot start dialogue with empty lines array")
		return

	# Initialize dialogue state
	dialogue_queue.clear()
	for line in lines:
		if line is DialogueLine:
			dialogue_queue.append(line)
		else:
			push_error("DialogueManager: Invalid line type in dialogue array")
			return

	current_line_index = -1
	is_dialogue_active = true
	is_paused = false

	# Create DialogueBox if needed
	_create_dialogue_box()

	# Clear any previous dialogue state
	if dialogue_box:
		dialogue_box.clear()

	# Show the box and start dialogue
	dialogue_box.show_box()
	await dialogue_box.dialogue_box_shown

	dialogue_started.emit()

	# Display first line
	_advance_to_next_line()

func start_simple_dialogue(text_lines: Array) -> void:
	"""Convenience method to start dialogue from simple string array"""
	var dialogue_lines: Array[DialogueLine] = []
	for text in text_lines:
		if text is String:
			dialogue_lines.append(DialogueLine.new(text))
	start_dialogue(dialogue_lines)

func _create_dialogue_box() -> void:
	"""Instantiate and set up the DialogueBox"""
	if dialogue_box:
		return  # Already exists

	dialogue_box = dialogue_box_scene.instantiate()
	canvas_layer.add_child(dialogue_box)

	# Connect signals
	dialogue_box.dialogue_advanced.connect(_on_dialogue_advanced)
	dialogue_box.dialogue_box_hidden.connect(_on_dialogue_box_hidden)

func _advance_to_next_line() -> void:
	"""Display the next line in the dialogue queue"""
	current_line_index += 1

	if current_line_index >= dialogue_queue.size():
		# All lines complete
		_end_dialogue()
		return

	var line: DialogueLine = dialogue_queue[current_line_index]

	# Emit line changed signal
	line_changed.emit(current_line_index)

	# Display the line
	dialogue_box.show_dialogue(line.text, line.character, line.audio_path)

	# Wait for text to complete
	await dialogue_box.text_fully_displayed

	# Execute callback if provided
	if line.callback.is_valid():
		line.callback.call()

	# Auto-advance if pause_duration is set
	if line.pause_duration > 0.0 and not is_paused:
		await get_tree().create_timer(line.pause_duration).timeout
		if is_dialogue_active and not is_paused:  # Check still active
			_advance_to_next_line()

func _on_dialogue_advanced() -> void:
	"""Called when player presses button to advance dialogue"""
	if not is_dialogue_active or is_paused:
		return

	_advance_to_next_line()

func _end_dialogue() -> void:
	"""End the current dialogue sequence"""
	if not is_dialogue_active:
		return

	is_dialogue_active = false
	dialogue_queue.clear()
	current_line_index = -1

	# Hide the dialogue box
	if dialogue_box:
		dialogue_box.hide_box()
		# Wait for hide animation, then emit finished signal

func _on_dialogue_box_hidden() -> void:
	"""Called when dialogue box finishes hiding"""
	if not is_dialogue_active and current_line_index == -1:
		# Only emit finished if we completed naturally (not skipped to new dialogue)
		dialogue_finished.emit()

func skip_dialogue() -> void:
	"""Force-skip the current dialogue sequence"""
	if not is_dialogue_active or not allow_skip:
		return

	dialogue_skipped.emit()

	# Clear state
	dialogue_queue.clear()
	current_line_index = -1
	is_dialogue_active = false

	# Hide box immediately
	if dialogue_box:
		dialogue_box.visible = false
		dialogue_box.clear()

	dialogue_finished.emit()

func pause_dialogue() -> void:
	"""Pause the current dialogue (prevents auto-advance and input)"""
	is_paused = true

func resume_dialogue() -> void:
	"""Resume paused dialogue"""
	is_paused = false

func is_active() -> bool:
	"""Check if dialogue is currently active"""
	return is_dialogue_active

func get_current_line_index() -> int:
	"""Get the index of the currently displayed line"""
	return current_line_index

func get_total_lines() -> int:
	"""Get the total number of lines in current dialogue"""
	return dialogue_queue.size()

func set_typing_speed(speed: float) -> void:
	"""Set the typing speed for the dialogue box"""
	if dialogue_box:
		dialogue_box.set_typing_speed(speed)

func set_dialogue_layer(layer: int) -> void:
	"""Temporarily change the dialogue canvas layer (useful for cutscenes)"""
	if canvas_layer:
		canvas_layer.layer = layer

func reset_dialogue_layer() -> void:
	"""Reset dialogue layer to default (99)"""
	if canvas_layer:
		canvas_layer.layer = 99

func cleanup() -> void:
	"""Clean up DialogueBox instance (useful for scene changes)"""
	if dialogue_box:
		dialogue_box.queue_free()
		dialogue_box = null

	is_dialogue_active = false
	dialogue_queue.clear()
	current_line_index = -1

# Helper function to create DialogueLine easily
static func create_line(text: String, character: String = "", pause: float = 0.0, callback: Callable = Callable(), audio_path: String = "") -> DialogueLine:
	"""Static helper to create a DialogueLine"""
	return DialogueLine.new(text, character, pause, callback, audio_path)

# Helper function to create DialogueLine with audio
static func create_line_with_audio(text: String, audio_path: String, character: String = "", pause: float = 0.0) -> DialogueLine:
	"""Static helper to create a DialogueLine with audio"""
	return DialogueLine.new(text, character, pause, Callable(), audio_path)

# Helper to create simple text-only dialogue
static func create_simple_lines(texts: Array[String]) -> Array[DialogueLine]:
	"""Static helper to create an array of DialogueLines from strings"""
	var lines: Array[DialogueLine] = []
	for text in texts:
		lines.append(DialogueLine.new(text))
	return lines

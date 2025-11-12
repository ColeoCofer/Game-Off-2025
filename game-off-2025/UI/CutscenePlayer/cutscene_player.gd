extends CanvasLayer
## Full-screen cutscene player for displaying images with dialogue overlay
## Supports frame sequencing, fade transitions, and skip functionality

# Signals
signal cutscene_started
signal cutscene_finished
signal cutscene_skipped
signal frame_changed(frame_index: int)

# Cutscene data structure
class CutsceneFrame:
	var image_path: String = ""
	var dialogue_lines: Array = []  # Array of strings for simple dialogue
	var duration: float = 0.0  # Auto-advance time in seconds (0 = manual)

	func _init(p_image_path: String = "", p_dialogue: Array = [], p_duration: float = 0.0):
		image_path = p_image_path
		dialogue_lines = p_dialogue
		duration = p_duration

# Node references
@onready var background: ColorRect = $Background
@onready var cutscene_image: TextureRect = $CutsceneImage
@onready var skip_indicator: Control = $SkipIndicator
@onready var skip_progress: ProgressBar = $SkipIndicator/HBoxContainer/ProgressBar

# Configuration
@export var fade_duration: float = 0.5  # Seconds for image fade transitions
@export var skip_hold_duration: float = 1.5  # How long to hold button to skip
@export var skip_button: String = "ui_cancel"  # Button to hold for skipping (ESC)

# State variables
var cutscene_frames: Array = []  # Array of CutsceneFrame
var current_frame_index: int = -1
var is_playing: bool = false
var is_skipping: bool = false
var skip_hold_time: float = 0.0

func _ready():
	# Hide by default
	visible = false
	skip_indicator.visible = false

func _process(delta):
	if not is_playing:
		return

	# Handle skip button hold
	if Input.is_action_pressed(skip_button):
		skip_hold_time += delta
		skip_progress.value = skip_hold_time / skip_hold_duration

		if not skip_indicator.visible:
			skip_indicator.visible = true

		# Skip when hold duration reached
		if skip_hold_time >= skip_hold_duration:
			skip_cutscene()
	else:
		# Reset skip progress
		skip_hold_time = 0.0
		skip_progress.value = 0.0
		if skip_indicator.visible:
			skip_indicator.visible = false

func play_cutscene(frames: Array) -> void:
	"""Start playing a cutscene sequence"""
	if is_playing:
		push_warning("CutscenePlayer: Cannot play cutscene while one is active")
		return

	if frames.is_empty():
		push_warning("CutscenePlayer: Cannot play cutscene with no frames")
		return

	# Initialize state
	cutscene_frames = frames.duplicate()
	current_frame_index = -1
	is_playing = true
	is_skipping = false
	skip_hold_time = 0.0

	# Set dialogue to appear above cutscene (layer 100 is above cutscene at 99)
	if DialogueManager:
		DialogueManager.set_dialogue_layer(100)

	# Show the cutscene player
	visible = true
	cutscene_started.emit()

	# Start with first frame
	await _advance_to_next_frame()

func _advance_to_next_frame() -> void:
	"""Display the next cutscene frame"""
	current_frame_index += 1

	if current_frame_index >= cutscene_frames.size():
		# All frames complete
		_end_cutscene()
		return

	var frame = cutscene_frames[current_frame_index]
	frame_changed.emit(current_frame_index)

	# Load and display image with fade
	await _display_frame_image(frame)

	# Pause to let player see the full image before dialogue appears
	await get_tree().create_timer(0.7).timeout

	# Display dialogue if any
	if not frame.dialogue_lines.is_empty():
		await _display_frame_dialogue(frame)

	# Auto-advance to next frame
	if frame.duration > 0.0:
		# Wait for duration before advancing
		await get_tree().create_timer(frame.duration).timeout

	# Advance to next frame (if still playing and not skipping)
	if is_playing and not is_skipping:
		await _advance_to_next_frame()

func _display_frame_image(frame: CutsceneFrame) -> void:
	"""Load and fade in the cutscene image"""
	# Load texture
	var texture = load(frame.image_path) as Texture2D
	if not texture:
		push_error("CutscenePlayer: Failed to load image: " + frame.image_path)
		return

	# Fade out current image
	if cutscene_image.texture:
		var fade_out = create_tween()
		fade_out.set_ease(Tween.EASE_IN)
		fade_out.set_trans(Tween.TRANS_CUBIC)
		fade_out.tween_property(cutscene_image, "modulate:a", 0.0, fade_duration * 0.5)
		await fade_out.finished

	# Set new texture
	cutscene_image.texture = texture

	# Fade in new image
	var fade_in = create_tween()
	fade_in.set_ease(Tween.EASE_OUT)
	fade_in.set_trans(Tween.TRANS_CUBIC)
	fade_in.tween_property(cutscene_image, "modulate:a", 1.0, fade_duration)
	await fade_in.finished

func _display_frame_dialogue(frame: CutsceneFrame) -> void:
	"""Display dialogue for this frame using DialogueManager"""
	if not DialogueManager:
		push_error("CutscenePlayer: DialogueManager not found")
		return

	# Start dialogue
	DialogueManager.start_simple_dialogue(frame.dialogue_lines)

	# Wait for dialogue to finish
	await DialogueManager.dialogue_finished

func _end_cutscene() -> void:
	"""End the cutscene sequence"""
	if not is_playing:
		return

	is_playing = false
	skip_indicator.visible = false

	# Fade out the image
	var fade_out = create_tween()
	fade_out.set_ease(Tween.EASE_IN)
	fade_out.set_trans(Tween.TRANS_CUBIC)
	fade_out.tween_property(cutscene_image, "modulate:a", 0.0, fade_duration)
	await fade_out.finished

	visible = false
	cutscene_image.modulate.a = 1.0
	cutscene_image.texture = null

	# Reset dialogue layer to default
	if DialogueManager:
		DialogueManager.reset_dialogue_layer()

	cutscene_finished.emit()

func skip_cutscene() -> void:
	"""Force skip the current cutscene"""
	if not is_playing or is_skipping:
		return

	is_skipping = true
	cutscene_skipped.emit()

	# Skip any active dialogue
	if DialogueManager and DialogueManager.is_active():
		DialogueManager.skip_dialogue()

	# End cutscene immediately
	is_playing = false
	skip_indicator.visible = false
	visible = false
	cutscene_image.texture = null
	cutscene_image.modulate.a = 1.0

	# Reset dialogue layer to default
	if DialogueManager:
		DialogueManager.reset_dialogue_layer()

	cutscene_finished.emit()

func is_cutscene_active() -> bool:
	"""Check if a cutscene is currently playing"""
	return is_playing

func get_current_frame_index() -> int:
	"""Get the index of the current frame"""
	return current_frame_index

func get_total_frames() -> int:
	"""Get the total number of frames"""
	return cutscene_frames.size()

# Helper function to create a cutscene frame
static func create_frame(image_path: String, dialogue: Array = [], duration: float = 0.0) -> CutsceneFrame:
	"""Static helper to create a CutsceneFrame"""
	return CutsceneFrame.new(image_path, dialogue, duration)

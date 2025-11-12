extends Node
## Test scene for CutscenePlayer
## Demonstrates cutscene image display with dialogue overlay

@onready var cutscene_player = $CutscenePlayer
@onready var instructions = $CanvasLayer/Instructions

var cutscene_started = false

func _ready():
	# Connect signals
	cutscene_player.cutscene_started.connect(_on_cutscene_started)
	cutscene_player.cutscene_finished.connect(_on_cutscene_finished)
	cutscene_player.cutscene_skipped.connect(_on_cutscene_skipped)
	cutscene_player.frame_changed.connect(_on_frame_changed)

	print("=== CutscenePlayer Test Ready ===")
	print("Press SPACE to start test cutscene")

func _input(event):
	if event.is_action_pressed("ui_accept") and not cutscene_started:
		start_test_cutscene()

func start_test_cutscene():
	"""Start a test cutscene using the actual cutscene images"""
	cutscene_started = true
	instructions.visible = false

	print("Starting test cutscene...")

	# Create cutscene frames using your actual images
	var frames = []

	# Frame 1: Sona looking at photo shard
	frames.append(cutscene_player.create_frame(
		"res://Assets/Art/cut-scenes/looking-at-first-scrappng.png",
		[
			"This photo...it looks familiar...",
			"I think it's of me and my mom...right before..."
		]
	))

	# Frame 2: Sona close-up sad
	frames.append(cutscene_player.create_frame(
		"res://Assets/Art/cut-scenes/sona-close-up-sad.png",
		[
			"It kills me to be so alone...",
			"There could be others out there..."
		]
	))

	# Frame 3: Sona with full photo
	frames.append(cutscene_player.create_frame(
		"res://Assets/Art/cut-scenes/sona-full-photo-above.png",
		[
			"But I lost my only family before I learned to fly...",
			"Maybe there's another way..."
		]
	))

	# Start the cutscene
	cutscene_player.play_cutscene(frames)

func _on_cutscene_started():
	print("✓ Cutscene started")

func _on_cutscene_finished():
	print("✓ Cutscene finished")
	cutscene_started = false
	instructions.visible = true
	instructions.text = "Cutscene complete!\n\nPress SPACE to play again"

func _on_cutscene_skipped():
	print("⚠ Cutscene skipped by player")

func _on_frame_changed(frame_index: int):
	print("→ Now showing frame %d/%d" % [frame_index + 1, cutscene_player.get_total_frames()])

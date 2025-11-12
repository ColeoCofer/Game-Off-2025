extends Node
## Test scene for DialogueManager autoload singleton
## Tests various dialogue features and functionality

@onready var status_label = $CanvasLayer/StatusLabel
@onready var buttons_container = $CanvasLayer/VBoxContainer

var callback_count = 0

func _ready():
	# Connect to DialogueManager signals
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_skipped.connect(_on_dialogue_skipped)

	update_status("Ready - Press a button to test")

func _input(event):
	# Press ESC to skip dialogue
	if event.is_action_pressed("pause"):
		if DialogueManager.is_active():
			DialogueManager.skip_dialogue()

func _on_test_1_button_pressed():
	"""Test 1: Simple dialogue sequence"""
	update_status("Test 1: Simple dialogue...")
	disable_buttons()

	var lines = [
		"Welcome to the DialogueManager test!",
		"This is a simple dialogue sequence.",
		"Press Space or Enter to advance through the lines.",
		"You can also press ESC to skip at any time.",
		"This is the last line!"
	]

	DialogueManager.start_simple_dialogue(lines)

func _on_test_2_button_pressed():
	"""Test 2: Dialogue with character names"""
	update_status("Test 2: Dialogue with character names...")
	disable_buttons()

	var lines: Array[DialogueManager.DialogueLine] = []
	lines.append(DialogueManager.create_line("Hello! I'm Sona the bat.", "Sona"))
	lines.append(DialogueManager.create_line("Nice to meet you, Sona!", "Player"))
	lines.append(DialogueManager.create_line("I'm trying to find my way through these caves.", "Sona"))
	lines.append(DialogueManager.create_line("Good luck on your journey!", "Player"))

	DialogueManager.start_dialogue(lines)

func _on_test_3_button_pressed():
	"""Test 3: Auto-advancing dialogue with pauses"""
	update_status("Test 3: Auto-advancing dialogue...")
	disable_buttons()

	var lines: Array[DialogueManager.DialogueLine] = []
	lines.append(DialogueManager.create_line("This dialogue will auto-advance...", "", 2.0))
	lines.append(DialogueManager.create_line("...after a 2 second pause.", "", 2.0))
	lines.append(DialogueManager.create_line("You can also press Space to advance immediately!", "", 2.0))
	lines.append(DialogueManager.create_line("Final line (manual advance).", ""))

	DialogueManager.start_dialogue(lines)

func _on_test_4_button_pressed():
	"""Test 4: Dialogue with callbacks"""
	update_status("Test 4: Dialogue with callbacks...")
	disable_buttons()
	callback_count = 0

	var lines: Array[DialogueManager.DialogueLine] = []
	lines.append(DialogueManager.create_line(
		"Callbacks can trigger code after each line!",
		"",
		0.0,
		_test_callback.bind("First callback!")
	))
	lines.append(DialogueManager.create_line(
		"Check the status label below...",
		"",
		0.0,
		_test_callback.bind("Second callback!")
	))
	lines.append(DialogueManager.create_line(
		"Callbacks are useful for triggering events!",
		"",
		0.0,
		_test_callback.bind("Third callback!")
	))
	lines.append(DialogueManager.create_line(
		"Like spawning objects, playing sounds, or changing game state.",
		"",
		0.0,
		_test_callback.bind("Final callback!")
	))

	DialogueManager.start_dialogue(lines)

func _test_callback(message: String):
	"""Example callback function"""
	callback_count += 1
	print("Callback #%d: %s" % [callback_count, message])
	update_status("Callback #%d: %s" % [callback_count, message])

func _on_dialogue_started():
	"""Called when dialogue begins"""
	print("DialogueManager: Dialogue started")
	update_status("Dialogue active...")

func _on_dialogue_finished():
	"""Called when dialogue completes or is skipped"""
	print("DialogueManager: Dialogue finished")
	update_status("Dialogue complete! Press another button to test.")
	enable_buttons()

func _on_line_changed(line_index: int):
	"""Called when a new line is displayed"""
	print("DialogueManager: Now showing line %d/%d" % [line_index + 1, DialogueManager.get_total_lines()])

func _on_dialogue_skipped():
	"""Called when dialogue is force-skipped"""
	print("DialogueManager: Dialogue was skipped!")
	update_status("Dialogue skipped!")

func update_status(text: String):
	"""Update the status label"""
	status_label.text = text

func disable_buttons():
	"""Disable all test buttons"""
	for button in buttons_container.get_children():
		if button is Button:
			button.disabled = true

func enable_buttons():
	"""Enable all test buttons"""
	for button in buttons_container.get_children():
		if button is Button:
			button.disabled = false

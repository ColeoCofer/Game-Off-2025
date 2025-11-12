extends Node
## Ultra-simple DialogueManager test
## Just press Space to trigger dialogue

func _ready():
	print("=== Simple Dialogue Test Ready ===")
	print("Press SPACE to start dialogue")
	print("DialogueManager exists: ", DialogueManager != null)

	# Connect signals
	if DialogueManager:
		DialogueManager.dialogue_started.connect(func(): print("✓ Dialogue started!"))
		DialogueManager.dialogue_finished.connect(func(): print("✓ Dialogue finished!"))

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("Space pressed - starting dialogue...")

		if not DialogueManager:
			print("ERROR: DialogueManager not found!")
			return

		if DialogueManager.is_active():
			print("Dialogue already active")
			return

		# Start simple dialogue
		var lines = [
			"Line 1: Hello from DialogueManager!",
			"Line 2: Press Space to advance.",
			"Line 3: This is the final line."
		]

		print("Calling start_simple_dialogue with ", lines.size(), " lines")
		DialogueManager.start_simple_dialogue(lines)

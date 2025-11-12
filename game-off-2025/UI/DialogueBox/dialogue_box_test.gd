extends Node

@onready var dialogue_box = $CanvasLayer/DialogueBox
@onready var test_button = $CanvasLayer/TestButton

# Test dialogue lines
var test_dialogues = [
	"This is the first line of dialogue. Press Space or Enter to continue.",
	"Here's the second line. Notice the typewriter effect as text appears character by character!",
	"You can press Space/Enter while text is appearing to make it complete instantly.",
	"This is a longer piece of dialogue to test text wrapping. The dialogue box should handle longer text gracefully and wrap it properly within the available space.",
	"Final line! The dialogue box will hide after this."
]

var current_dialogue_index = 0
var dialogue_active = false

func _ready():
	# Connect dialogue box signals
	dialogue_box.dialogue_advanced.connect(_on_dialogue_advanced)
	dialogue_box.dialogue_box_hidden.connect(_on_dialogue_box_hidden)

func _on_test_button_pressed():
	start_dialogue_sequence()

func start_dialogue_sequence():
	"""Begin the test dialogue sequence"""
	if dialogue_active:
		return

	dialogue_active = true
	current_dialogue_index = 0
	test_button.disabled = true

	# Show the dialogue box
	dialogue_box.show_box()
	await dialogue_box.dialogue_box_shown

	# Display first line
	display_current_dialogue()

func display_current_dialogue():
	"""Display the current dialogue line"""
	if current_dialogue_index < test_dialogues.size():
		dialogue_box.show_dialogue(test_dialogues[current_dialogue_index])

func _on_dialogue_advanced():
	"""Called when player presses button to advance"""
	current_dialogue_index += 1

	if current_dialogue_index < test_dialogues.size():
		# More dialogue to show
		display_current_dialogue()
	else:
		# All dialogue complete
		end_dialogue_sequence()

func end_dialogue_sequence():
	"""End the dialogue sequence"""
	dialogue_box.hide_box()

func _on_dialogue_box_hidden():
	"""Called when dialogue box finishes hiding"""
	dialogue_active = false
	test_button.disabled = false
	print("Dialogue sequence complete!")

# Alternative: Manual input handling (if not using dialogue_advanced signal)
func _input(event):
	if not dialogue_active:
		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			start_dialogue_sequence()

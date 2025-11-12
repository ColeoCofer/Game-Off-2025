extends Node
## Simple script to test dialogue box in a level
## Usage:
##   1. Add a Node to your level and attach this script
##   2. Add a CanvasLayer as a child of that Node
##   3. Add DialogueBox as a child of the CanvasLayer
##   Node structure: Node → CanvasLayer → DialogueBox

@onready var dialogue_box = $CanvasLayer/DialogueBox

var test_lines = [
	"Welcome to Level 1!",
	"This is how dialogue will appear in the game.",
	"Pretty cool, right?"
]
var current_index = 0
var dialogue_started = false

func _ready():
	if dialogue_box:
		dialogue_box.dialogue_advanced.connect(_on_dialogue_advanced)
		# Auto-start after a short delay
		await get_tree().create_timer(1.0).timeout
		start_test_dialogue()

func _input(event):
	# Press T to manually trigger dialogue test
	if event.is_action_pressed("ui_cancel") and not dialogue_started:  # ESC key
		start_test_dialogue()

func start_test_dialogue():
	if dialogue_started:
		return

	dialogue_started = true
	current_index = 0
	dialogue_box.show_box()
	await dialogue_box.dialogue_box_shown
	show_next_line()

func show_next_line():
	if current_index < test_lines.size():
		dialogue_box.show_dialogue(test_lines[current_index])
	else:
		end_dialogue()

func _on_dialogue_advanced():
	current_index += 1
	show_next_line()

func end_dialogue():
	dialogue_box.hide_box()
	await dialogue_box.dialogue_box_hidden
	dialogue_started = false
	print("Dialogue test complete!")

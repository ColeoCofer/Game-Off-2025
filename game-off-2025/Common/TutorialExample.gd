extends Node
## Example script showing how to use the TutorialManager
## This is just for reference - you can delete this file

func _ready():
	# Wait a bit for everything to load
	await get_tree().create_timer(2.0).timeout

	# Example 1: Show a tutorial once (persists across game sessions)
	TutorialManager.show_tutorial_once(
		"jump_tutorial",
		"Press SPACE to jump!",
		"[Press SPACE]",
		3.0  # Auto-dismiss after 3 seconds
	)

func show_wall_jump_tutorial():
	"""Example: Show a tutorial that can be shown multiple times in a session"""
	TutorialManager.show_tutorial(
		"wall_jump_tip",
		"Jump against walls to climb higher!",
		"[Press SPACE near wall]",
		4.0
	)

func show_flap_tutorial():
	"""Example: Show a persistent tutorial (only once ever)"""
	TutorialManager.show_tutorial_once(
		"flap_tutorial",
		"Press J to flap your wings and slow your fall!",
		"[Press J to flap]",
		0.0  # Manual dismiss only (player must press SPACE)
	)

func show_run_tutorial():
	"""Example: Tutorial with custom input hint"""
	TutorialManager.show_tutorial_once(
		"run_tutorial",
		"Hold SHIFT while moving to run faster!",
		"[Hold SHIFT + A/D]",
		5.0
	)

# You can also manually check if a tutorial is showing:
func _process(_delta):
	if TutorialManager.is_tutorial_active():
		# Pause gameplay or disable certain actions
		pass

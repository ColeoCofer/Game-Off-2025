extends Node
## Example test script showing how to use CutsceneDirector
## This demonstrates creating a simple in-level cutscene

func _ready():
	print("=== Cutscene Director Test ===")
	print("Waiting for scene to load...")

	# Wait for scene to be ready
	await get_tree().create_timer(1.0).timeout

	# Create a simple test cutscene
	create_test_cutscene()

	# Play it
	CutsceneDirector.play_cutscene("test_cutscene")

func create_test_cutscene():
	"""Create a simple test cutscene sequence"""
	var actions = []

	# Step 1: Show dialogue
	actions.append(CutsceneDirector.action_dialogue([
		"Welcome to the cutscene system test!",
		"Player control has been disabled.",
		"Watch as Sona moves automatically..."
	]))

	# Step 2: Wait a moment
	actions.append(CutsceneDirector.action_wait(0.5))

	# Step 3: Make player walk
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		var target_x = player.global_position.x + 200
		actions.append(CutsceneDirector.action_player_walk(target_x, 80.0))

	# Step 4: More dialogue
	actions.append(CutsceneDirector.action_dialogue([
		"Sona walked forward!",
		"Now control will be restored."
	]))

	# Register the cutscene
	CutsceneDirector.register_cutscene("test_cutscene", actions)
	print("Test cutscene registered!")

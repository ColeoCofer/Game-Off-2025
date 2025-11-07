extends Area2D

signal level_completed

@export var completion_delay: float = 0.3

var level_complete: bool = false

func _ready():
	# Connect to body_entered signal
	body_entered.connect(_on_body_entered)
	print("LevelCompleteArea ready - waiting for player")

func _on_body_entered(body: Node2D):
	print("Body entered level complete area: ", body.name, " Groups: ", body.get_groups())
	# Check if it's the player
	if body.is_in_group("Player") and not level_complete:
		print("Player detected! Triggering level complete")
		level_complete = true
		_trigger_level_complete(body)
	else:
		print("Not player or already complete")

func _trigger_level_complete(player: CharacterBody2D):
	"""Called when player reaches the completion area"""
	# Disable player control
	player.set_physics_process(false)

	# Wait a moment before showing menu
	await get_tree().create_timer(completion_delay).timeout

	# Show the completion menu
	_show_completion_menu()

	level_completed.emit()

func _show_completion_menu():
	"""Show the death menu but with success message"""
	# Notify SceneManager of level completion
	SceneManager.complete_level()

	# Find or create the death menu (we'll reuse it for completion)
	var death_menu = get_tree().get_first_node_in_group("DeathMenu")

	if not death_menu:
		# If menu doesn't exist in the scene, we need to add it
		var canvas_layer = get_tree().get_first_node_in_group("UI_Layer")
		if not canvas_layer:
			# Create a canvas layer if it doesn't exist
			canvas_layer = CanvasLayer.new()
			canvas_layer.add_to_group("UI_Layer")
			canvas_layer.layer = 100  # Make sure it's on top
			get_tree().root.add_child(canvas_layer)

		# Load and instance the death menu
		var death_menu_scene = load("res://UI/death_menu.tscn")
		death_menu = death_menu_scene.instantiate()
		death_menu.add_to_group("DeathMenu")
		canvas_layer.add_child(death_menu)

	if death_menu.has_method("show_menu"):
		death_menu.show_menu("success")

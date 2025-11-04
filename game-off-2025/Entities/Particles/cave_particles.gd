extends CPUParticles2D

# Majestic floating cave particles that flow across the screen

@onready var camera: Camera2D

func _ready():
	# Make sure particles are emitting
	emitting = true
	randomize()

	# Find the camera to follow
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node_or_null("Camera2D")
		if not camera:
			# Try to find any camera in the scene
			camera = get_viewport().get_camera_2d()

func _process(_delta):
	if camera:
		# Position particles to emit from right side of visible screen
		var camera_pos = camera.get_screen_center_position()
		var viewport_size = get_viewport_rect().size

		# Emit from right edge of screen, centered vertically
		position = camera_pos + Vector2(viewport_size.x * 0.6, 0)

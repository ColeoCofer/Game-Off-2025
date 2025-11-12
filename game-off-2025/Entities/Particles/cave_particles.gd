extends CPUParticles2D

# Majestic floating cave particles that flow across the screen

func _ready():
	# Make sure particles are emitting
	emitting = true
	visible = true
	randomize()

	# Find the camera to attach to
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("Player")
	var camera: Camera2D = null

	if player:
		camera = player.get_node_or_null("Camera2D")
		if not camera:
			# Try to find any camera in the scene
			camera = get_viewport().get_camera_2d()

	if camera:
		# Reparent to camera so particles follow it
		var old_parent = get_parent()
		old_parent.remove_child(self)
		camera.add_child(self)

		# Position to emit from right side of screen
		var viewport_size = get_viewport_rect().size
		position = Vector2(viewport_size.x * 0.6, 0)

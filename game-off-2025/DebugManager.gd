extends CanvasLayer

# DEBUG MODE - TODO: Remove for production
# This singleton manages debug settings across the game
var debug_mode: bool = false

# FPS display
var fps_label: Label = null

func _ready():
	# Set layer to be on top
	layer = 128

	# Create FPS label
	fps_label = Label.new()
	fps_label.name = "FPSLabel"
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))  # Yellow text
	fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))  # Black outline
	fps_label.add_theme_constant_override("outline_size", 4)  # Outline for readability
	fps_label.z_index = 1000
	fps_label.visible = debug_mode
	add_child(fps_label)

func _process(_delta):
	if debug_mode and fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		fps_label.visible = true

		# Position in lower right corner (accounting for viewport size)
		var viewport_size = get_viewport().get_visible_rect().size
		var label_size = fps_label.get_combined_minimum_size()
		fps_label.position = Vector2(
			viewport_size.x - label_size.x - 10,  # 10px from right edge
			viewport_size.y - label_size.y - 10   # 10px from bottom edge
		)
	elif fps_label:
		fps_label.visible = false

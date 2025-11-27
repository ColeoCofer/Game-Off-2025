extends Control
## Credit roll scene - displays scrolling credits over the title background

signal credits_finished

# Configuration
@export var scroll_speed: float = 30.0  ## Pixels per second
@export var fade_in_duration: float = 1.0
@export var hold_at_end_duration: float = 3.0
@export var fade_out_duration: float = 1.5

# References
@onready var credits_container: VBoxContainer = $CreditsContainer
@onready var background: TextureRect = $Background

# State
var is_scrolling: bool = false
var scroll_start_y: float = 0.0
var scroll_end_y: float = 0.0
var can_skip: bool = false

func _ready():
	# Start credits off-screen (below the viewport)
	scroll_start_y = get_viewport_rect().size.y
	credits_container.position.y = scroll_start_y

	# Calculate where to stop (when last credit is centered)
	# We'll calculate this after the container is sized
	await get_tree().process_frame
	scroll_end_y = -credits_container.size.y + (get_viewport_rect().size.y * 0.4)

	# Start the credit sequence
	start_credits()

func _input(event):
	if can_skip and event.is_action_pressed("ui_accept"):
		# Skip to end
		finish_credits()

func start_credits():
	# Fade in from black
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)
	await fade_tween.finished

	# Allow skipping after fade in
	can_skip = true

	# Start scrolling
	is_scrolling = true

func _process(delta):
	if not is_scrolling:
		return

	# Scroll credits upward
	credits_container.position.y -= scroll_speed * delta

	# Check if we've reached the end
	if credits_container.position.y <= scroll_end_y:
		credits_container.position.y = scroll_end_y
		is_scrolling = false
		hold_and_finish()

func hold_and_finish():
	# Hold at the end for a moment
	await get_tree().create_timer(hold_at_end_duration).timeout
	finish_credits()

func finish_credits():
	if not is_scrolling:
		is_scrolling = false  # Ensure scrolling stops
	can_skip = false

	# Fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	await fade_tween.finished

	credits_finished.emit()

	# Return to main menu
	SceneManager.goto_main_menu()

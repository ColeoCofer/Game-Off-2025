extends AnimatableBody2D

enum MovementDirection {
	HORIZONTAL,
	VERTICAL
}

@export var movement_direction: MovementDirection = MovementDirection.HORIZONTAL
@export var move_speed: float = 50.0
@export var move_distance: float = 100.0
@export_range(0.0, 1.0, 0.01) var time_offset: float = 0.0  ## Offset as percentage of cycle (0-1)

var start_position: float
var direction: int = 1  # 1 for right/down, -1 for left/up
var time_elapsed: float = 0.0
var cycle_time: float

func _ready():
	# Set starting position based on movement direction
	if movement_direction == MovementDirection.HORIZONTAL:
		start_position = global_position.x  # Starting position is the leftmost point
	else:
		start_position = global_position.y  # Starting position is the topmost point

	sync_to_physics = true

	# Calculate how long one full cycle takes (start to end and back)
	cycle_time = (move_distance * 2.0) / move_speed

	# Apply time offset to start at a different point in the cycle
	time_elapsed = time_offset * cycle_time

	# Set initial position based on offset
	_update_position_from_time()

func _physics_process(delta):
	time_elapsed += delta

	# Loop the time
	if time_elapsed >= cycle_time:
		time_elapsed -= cycle_time

	_update_position_from_time()

func _update_position_from_time():
	# Calculate position based on time in cycle
	var half_cycle = cycle_time / 2.0

	if time_elapsed < half_cycle:
		# Moving forward (first half of cycle - right for horizontal, down for vertical)
		var progress = time_elapsed / half_cycle
		var new_position = start_position + (move_distance * progress)

		if movement_direction == MovementDirection.HORIZONTAL:
			global_position.x = new_position
		else:
			global_position.y = new_position

		direction = 1
	else:
		# Moving backward (second half of cycle - left for horizontal, up for vertical)
		var progress = (time_elapsed - half_cycle) / half_cycle
		var new_position = start_position + move_distance - (move_distance * progress)

		if movement_direction == MovementDirection.HORIZONTAL:
			global_position.x = new_position
		else:
			global_position.y = new_position

		direction = -1

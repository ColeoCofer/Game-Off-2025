extends AnimatableBody2D

@export var move_speed: float = 50.0
@export var move_distance: float = 100.0
@export_range(0.0, 1.0, 0.01) var time_offset: float = 0.0  ## Offset as percentage of cycle (0-1)

var left_position: float
var direction: int = 1  # 1 for right, -1 for left
var time_elapsed: float = 0.0
var cycle_time: float

func _ready():
	left_position = global_position.x  # Starting position is the leftmost point
	sync_to_physics = true

	# Calculate how long one full cycle takes (left to right and back)
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
		# Moving right (first half of cycle)
		var progress = time_elapsed / half_cycle
		global_position.x = left_position + (move_distance * progress)
		direction = 1
	else:
		# Moving left (second half of cycle)
		var progress = (time_elapsed - half_cycle) / half_cycle
		global_position.x = left_position + move_distance - (move_distance * progress)
		direction = -1

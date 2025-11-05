extends AnimatableBody2D

@export var move_speed: float = 50.0
@export var move_distance: float = 100.0

var left_position: float
var direction: int = 1  # 1 for right, -1 for left

func _ready():
	left_position = global_position.x  # Starting position is the leftmost point
	sync_to_physics = true

func _physics_process(delta):
	# Move the platform
	global_position.x += move_speed * direction * delta

	# Check if we've reached the boundaries
	if direction == 1 and global_position.x >= left_position + move_distance:
		# Reached right side, reverse
		global_position.x = left_position + move_distance
		direction = -1
	elif direction == -1 and global_position.x <= left_position:
		# Reached left side, reverse
		global_position.x = left_position
		direction = 1

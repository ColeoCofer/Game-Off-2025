extends Node2D

## Falling stalagmite platform that triggers animation when player is nearby
## - Detects player within a specified distance
## - Triggers the stalagmite falling animation using AnimationPlayer
## - Only triggers once (doesn't reset)
## - AnimationPlayer can animate both the sprite AND collision shapes

@export var detection_distance: float = 100.0  ## Distance to detect player (pixels)
@export var one_time_trigger: bool = true  ## If true, only triggers once and doesn't reset
@export var animation_name: String = "fall"  ## Name of the animation to play
@export var cooldown_duration: float = 2.0  ## Time in seconds before the trap can trigger again

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var damage_area: Area2D = $Visuals/DamageArea
@onready var damage_area2: Area2D = $Visuals/DamageArea2

var has_triggered: bool = false
var is_on_cooldown: bool = false
var player_in_range: bool = false

func _ready():
	# Set up the detection area
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)

	# Set up damage areas
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_body_entered)
	if damage_area2:
		damage_area2.body_entered.connect(_on_damage_area_body_entered)

	# Connect to animation finished signal to reset
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

	# Configure the detection shape based on the exported distance
	_update_detection_shape()

func _update_detection_shape():
	if detection_shape and detection_shape.shape is CircleShape2D:
		detection_shape.shape.radius = detection_distance

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_in_range = true
		print("Player entered range")
		_try_trigger()

func _on_detection_area_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		player_in_range = false
		print("Player exited range")

func _try_trigger():
	# Check if we can trigger
	print("Try trigger - On cooldown: ", is_on_cooldown, " | Has triggered: ", has_triggered, " | One time: ", one_time_trigger)
	if is_on_cooldown:
		print("Blocked by cooldown")
		return

	if one_time_trigger and has_triggered:
		print("Blocked by one_time_trigger")
		return

	print("Triggering fall!")
	_trigger_fall()

func _trigger_fall():
	has_triggered = true

	# Play the falling animation using AnimationPlayer
	if animation_player and animation_player.has_animation(animation_name):
		animation_player.play(animation_name)

func _on_animation_finished(anim_name: String):
	# Only reset if it was our fall animation
	if anim_name == animation_name:
		print("Animation finished: ", anim_name)
		# Reset the animation to the beginning
		if animation_player:
			animation_player.stop()
			animation_player.play("RESET")

		# Start cooldown timer
		print("Starting cooldown for ", cooldown_duration, " seconds")
		is_on_cooldown = true
		await get_tree().create_timer(cooldown_duration).timeout
		is_on_cooldown = false
		print("Cooldown finished!")

		# Reset has_triggered if not in one_time_trigger mode
		if not one_time_trigger:
			has_triggered = false
			print("has_triggered reset to false")

		# Check if player is still in range and trigger again
		if player_in_range:
			print("Player still in range, retriggering!")
			_try_trigger()

func _on_damage_area_body_entered(body: Node2D):
	# Kill the player when they touch the falling stalagmite
	if body.is_in_group("Player"):
		_kill_player(body)

func _kill_player(player: Node2D):
	# Find and trigger the player's death manager
	var death_manager = player.get_node_or_null("DeathManager")
	if death_manager and death_manager.has_method("trigger_hazard_death"):
		death_manager.trigger_hazard_death()

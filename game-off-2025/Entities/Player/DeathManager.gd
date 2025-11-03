extends Node

signal death_animation_complete

@export var death_animation_duration: float = 2.0
@export var rotation_speed: float = 3.0
@export var fall_speed: float = 100.0
@export var fall_death_distance: float = 500.0  # If you fall too far then you die

var is_dead: bool = false
var player: CharacterBody2D
var original_material: Material
var death_material: ShaderMaterial
var last_ground_y: float = 0.0
var camera: Camera2D
var death_reason: String = "starvation"  # Track how the player died

func _ready():
	player = get_parent() as CharacterBody2D
	camera = player.get_node_or_null("Camera2D")
	last_ground_y = player.position.y

	# Get the HungerManager and connect to its signal
	# hmm might be a safer way to do this
	var hunger_manager = player.get_node_or_null("HungerManager")
	if hunger_manager:
		hunger_manager.hunger_depleted.connect(_on_hunger_depleted)

func _physics_process(_delta):
	if is_dead:
		return

	# Track the last ground position
	if player.is_on_floor():
		last_ground_y = player.position.y

	# Check if player has fallen too far
	var fall_distance = player.position.y - last_ground_y
	if fall_distance > fall_death_distance:
		trigger_fall_death()

func _on_hunger_depleted():
	if not is_dead:
		trigger_death()

func trigger_fall_death():
	"""Called when player falls too far"""
	if is_dead:
		return

	is_dead = true
	death_reason = "fall"

	# Stop camera from following player
	if camera:
		camera.enabled = false

	# Disable player control
	player.set_physics_process(false)

	# Show death menu immediately after a brief delay
	await get_tree().create_timer(0.5).timeout
	_show_death_menu()

func trigger_death():
	is_dead = true
	death_reason = "starvation"

	# Disable player control
	player.set_physics_process(false)

	# Death shader
	_apply_death_shader()

	# Death animation
	_play_death_animation()

func _apply_death_shader():
	# Get the player's sprite
	var sprite = player.get_node_or_null("AnimatedSprite2D")
	if sprite:
		# Store original material
		original_material = sprite.material

		# Load and create death shader material
		var death_shader = load("res://Shaders/death_shader.gdshader")
		death_material = ShaderMaterial.new()
		death_material.shader = death_shader
		death_material.set_shader_parameter("death_progress", 0.0)
		death_material.set_shader_parameter("distortion_strength", 0.5)

		# Apply the shader material
		sprite.material = death_material

func _play_death_animation():
	var sprite = player.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		_finish_death()
		return

	# Create animation tween
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade death shader progress
	tween.tween_method(_update_death_shader, 0.0, 1.0, death_animation_duration)

	# Rotate the player
	tween.tween_property(sprite, "rotation", TAU * rotation_speed, death_animation_duration)

	# Shrink the player
	tween.tween_property(sprite, "scale", Vector2(0.3, 0.3), death_animation_duration)

	# Make player fall
	tween.tween_property(player, "position:y", player.position.y + fall_speed, death_animation_duration)

	# When animation completes, show death menu
	tween.finished.connect(_finish_death)

func _update_death_shader(progress: float):
	if death_material:
		death_material.set_shader_parameter("death_progress", progress)

func _finish_death():
	death_animation_complete.emit()
	_show_death_menu()

func _show_death_menu():
	# Find or create the death menu
	var death_menu = get_tree().get_first_node_in_group("DeathMenu")

	if not death_menu:
		# If menu doesn't exist in the scene, we need to add it
		# This assumes the menu is in a CanvasLayer... So gotta add that
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
		death_menu.show_menu(death_reason)

extends Node2D

# Torch light parameters
@export var light_energy: float = 2.0
@export var light_flicker_speed: float = 3.0
@export var light_flicker_intensity: float = 0.2

# Audio parameters
@export var max_audio_distance: float = 200.0  ## Distance at which fire sound is inaudible
@export var min_audio_distance: float = 50.0   ## Distance at which fire sound is at full volume
@export var torch_volume_db: float = 0.0        ## Volume of the torch fire sound in decibels (-80 to 24)

var time_passed: float = 0.0
var torch_audio_player: AudioStreamPlayer2D = null

func _ready():
	# Play the animation if it exists
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

	# Set up initial light energy
	if has_node("PointLight2D"):
		$PointLight2D.energy = light_energy

	# Setup torch audio player
	torch_audio_player = get_node_or_null("TorchAudioPlayer")

	# Create torch audio player if it doesn't exist
	if not torch_audio_player:
		torch_audio_player = AudioStreamPlayer2D.new()
		torch_audio_player.name = "TorchAudioPlayer"
		torch_audio_player.bus = &"Sounds"

		# Load and configure the torch sound for looping
		var torch_stream = load("res://Assets/Audio/fire/fire-torch.mp3")
		if torch_stream is AudioStreamMP3:
			torch_stream.loop = true
		torch_audio_player.stream = torch_stream

		torch_audio_player.volume_db = torch_volume_db
		torch_audio_player.autoplay = false
		torch_audio_player.max_distance = max_audio_distance
		torch_audio_player.attenuation = 2.0  # Exponential falloff
		add_child(torch_audio_player)

func _process(delta):
	# Create a flickering fire effect for the light
	time_passed += delta

	if has_node("PointLight2D"):
		# Combine multiple sine waves for more organic flickering
		var flicker1 = sin(time_passed * light_flicker_speed) * light_flicker_intensity
		var flicker2 = sin(time_passed * light_flicker_speed * 1.7) * (light_flicker_intensity * 0.5)
		var flicker3 = sin(time_passed * light_flicker_speed * 2.3) * (light_flicker_intensity * 0.3)

		$PointLight2D.energy = light_energy + flicker1 + flicker2 + flicker3

	# Update torch audio volume based on player proximity
	_update_torch_audio()

func _update_torch_audio():
	"""Update torch fire sound volume based on player distance"""
	if not torch_audio_player:
		return

	# Find the player in the scene
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		# Stop playing if no player found
		if torch_audio_player.playing:
			torch_audio_player.stop()
		return

	# Calculate distance to player
	var distance = global_position.distance_to(player.global_position)

	# Start/stop playing based on distance
	if distance <= max_audio_distance:
		# Start looping if not already playing
		if not torch_audio_player.playing:
			torch_audio_player.play()

		# The AudioStreamPlayer2D handles volume falloff automatically based on distance
	else:
		# Stop playing when too far away
		if torch_audio_player.playing:
			torch_audio_player.stop()

extends AudioStreamPlayer

func _ready():
	# Load the water drops audio
	stream = load("res://Assets/Audio/water_drops.wav")
	# Enable autoplay
	autoplay = true
	# Start playing
	play()

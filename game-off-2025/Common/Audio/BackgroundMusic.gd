extends AudioStreamPlayer

var water_drops_player: AudioStreamPlayer

func _ready():
	# Load the main background music
	stream = load("res://Assets/Audio/sona-main.mp3")
	bus = "Music"  # Use the Music bus

	# Load saved settings (check if SaveManager exists first)
	if has_node("/root/SaveManager"):
		volume_db = SaveManager.get_music_volume()

	# Create and setup water drops audio player
	water_drops_player = AudioStreamPlayer.new()
	water_drops_player.stream = load("res://Assets/Audio/water_drops.wav")
	water_drops_player.volume_db = -40  # Adjust this value to control water drops volume
	water_drops_player.bus = "Music"  # Use the Music bus
	add_child(water_drops_player)

	# Connect finished signal to loop the main music
	finished.connect(_on_music_finished)

	# Play on loop - will be paused if volume is at minimum
	autoplay = true
	play()
	water_drops_player.play()

	# Pause if volume is at minimum
	if volume_db <= -40.0:
		stream_paused = true
		water_drops_player.stream_paused = true

func _on_music_finished():
	# Replay the music when it finishes to create a loop
	play()

func set_volume(db_value: float):
	volume_db = db_value

	# Pause music if volume is at minimum (-40 dB)
	if db_value <= -40.0:
		if playing:
			stream_paused = true
		if water_drops_player and water_drops_player.playing:
			water_drops_player.stream_paused = true
	else:
		# Resume music if it was paused
		if playing and stream_paused:
			stream_paused = false
		elif not playing:
			play()

		if water_drops_player:
			if water_drops_player.playing and water_drops_player.stream_paused:
				water_drops_player.stream_paused = false
			elif not water_drops_player.playing:
				water_drops_player.play()

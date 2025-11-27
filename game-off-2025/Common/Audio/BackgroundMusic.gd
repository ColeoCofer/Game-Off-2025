extends AudioStreamPlayer

var water_drops_player: AudioStreamPlayer
var main_music_stream: AudioStream
var is_playing_special_song: bool = false
var loop_special_song: bool = false

func _ready():
	# Load the main background music
	main_music_stream = load("res://Assets/Audio/sona-main.mp3")
	stream = main_music_stream
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
	if is_playing_special_song:
		if loop_special_song:
			# Loop the special song
			play()
		else:
			# Special song finished - stay silent until resume_main_music() is called
			is_playing_special_song = false
	else:
		# Replay the main music when it finishes to create a loop
		play()


var original_volume_db: float = 0.0
var is_faded_out: bool = false

func fade_out(duration: float = 1.0):
	"""Fade out the background music over the specified duration, then stop completely."""
	if is_faded_out:
		return

	original_volume_db = volume_db
	is_faded_out = true

	var tween = create_tween()
	tween.tween_property(self, "volume_db", -40.0, duration)
	tween.tween_callback(stop)  # Stop playback after fade completes

	# Also fade out water drops
	if water_drops_player:
		var water_tween = create_tween()
		water_tween.tween_property(water_drops_player, "volume_db", -80.0, duration)
		water_tween.tween_callback(water_drops_player.stop)  # Stop water drops too


func play_special_song(song_path: String, loop: bool = false):
	"""Play a special song. If loop is true, it will repeat until stopped."""
	var special_stream = load(song_path)
	if special_stream:
		is_playing_special_song = true
		loop_special_song = loop
		stream = special_stream
		# Restore volume if we were faded out
		if is_faded_out:
			volume_db = original_volume_db
			is_faded_out = false
		play()
	else:
		push_error("Could not load special song: " + song_path)


func resume_main_music():
	"""Immediately resume the main background music."""
	is_playing_special_song = false
	loop_special_song = false
	is_faded_out = false
	stream = main_music_stream
	# Restore volume in case we were faded out
	if has_node("/root/SaveManager"):
		volume_db = SaveManager.get_music_volume()
	else:
		volume_db = original_volume_db
	play()

	# Also restore water drops
	if water_drops_player:
		water_drops_player.volume_db = -40
		if not water_drops_player.playing:
			water_drops_player.play()

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

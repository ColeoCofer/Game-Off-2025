extends AudioStreamPlayer

var music_enabled: bool = true
var water_drops_player: AudioStreamPlayer

func _ready():
	# Load the main background music
	stream = load("res://Assets/Audio/sona-main.mp3")

	# Load saved settings (check if SaveManager exists first)
	if has_node("/root/SaveManager"):
		music_enabled = SaveManager.get_music_enabled()
		volume_db = SaveManager.get_music_volume()

	# Create and setup water drops audio player
	water_drops_player = AudioStreamPlayer.new()
	water_drops_player.stream = load("res://Assets/Audio/water_drops.wav")
	water_drops_player.volume_db = -40  # Adjust this value to control water drops volume
	add_child(water_drops_player)

	# Play on loop if enabled
	if music_enabled:
		autoplay = true
		play()
		water_drops_player.play()

func toggle_music(enabled: bool):
	music_enabled = enabled
	if enabled:
		if not playing:
			play()
		if water_drops_player and not water_drops_player.playing:
			water_drops_player.play()
	else:
		stop()
		if water_drops_player:
			water_drops_player.stop()

func set_volume(db_value: float):
	volume_db = db_value

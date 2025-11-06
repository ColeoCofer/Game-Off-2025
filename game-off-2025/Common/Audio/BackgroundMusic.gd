extends AudioStreamPlayer

var music_enabled: bool = true

func _ready():
	# Load the main background music
	stream = load("res://Assets/Audio/sona-main.mp3")

	# Load saved settings
	music_enabled = SaveManager.get_music_enabled()
	volume_db = SaveManager.get_music_volume()

	# Play on loop if enabled
	if music_enabled:
		autoplay = true
		play()

func toggle_music(enabled: bool):
	music_enabled = enabled
	if enabled:
		if not playing:
			play()
	else:
		stop()

func set_volume(db_value: float):
	volume_db = db_value

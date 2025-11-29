extends Node

# Signals
signal hunger_changed(current: float, maximum: float)
signal hunger_depleted()
signal food_consumed(amount: float)

# Configuration
@export var max_hunger: float = 100.0
@export var depletion_rate: float = 4.0  # Hunger lost per second
@export var min_hunger: float = 0.0

# State
var current_hunger: float = 100.0
var is_depleting: bool = true

# Audio
var hurt_audio_player: AudioStreamPlayer
var firefly_sacrifice_audio_player: AudioStreamPlayer
var heartbeat_audio_player: AudioStreamPlayer

# Firefly protection
var firefly_manager: Node

# Heartbeat state
var is_heartbeat_playing: bool = false
var heartbeat_threshold: float = 20.0  # Play heartbeat below 20% hunger

# Death manager reference
var death_manager: Node

func _ready():
	current_hunger = max_hunger
	hunger_changed.emit(current_hunger, max_hunger)

	# Get reference to hurt audio player
	hurt_audio_player = get_parent().get_node("HurtAudioPlayer")

	# Get reference to firefly sacrifice audio player
	firefly_sacrifice_audio_player = get_parent().get_node("FireflySacrificeAudioPlayer")

	# Get reference to heartbeat audio player
	heartbeat_audio_player = get_parent().get_node("HeartbeatAudioPlayer")

	# Get reference to firefly manager
	firefly_manager = get_parent().get_node_or_null("FireflyManager")

	# Get reference to death manager
	death_manager = get_parent().get_node_or_null("DeathManager")

func _process(delta):
	if is_depleting:
		_deplete_hunger(delta)

func _deplete_hunger(delta: float):
	if current_hunger > min_hunger:
		current_hunger -= depletion_rate * delta
		current_hunger = max(current_hunger, min_hunger)
		hunger_changed.emit(current_hunger, max_hunger)

		# Update heartbeat sound based on hunger level
		_update_heartbeat()

		if current_hunger <= min_hunger:
			# Check if player has a firefly to sacrifice instead of dying
			if firefly_manager and firefly_manager.has_shield():
				_sacrifice_firefly_for_hunger()
			else:
				hunger_depleted.emit()

func consume_food(amount: float):
	current_hunger = min(current_hunger + amount, max_hunger)
	hunger_changed.emit(current_hunger, max_hunger)
	food_consumed.emit(amount)

	# Update heartbeat after consuming food
	_update_heartbeat()

func take_damage(amount: float):
	# Reduce hunger when taking damage
	current_hunger = max(current_hunger - amount, min_hunger)
	hunger_changed.emit(current_hunger, max_hunger)

	# Check if hunger depleted
	if current_hunger <= min_hunger:
		# Check if player has a firefly to sacrifice instead of dying
		if firefly_manager and firefly_manager.has_shield():
			_sacrifice_firefly_for_hunger()
		else:
			hunger_depleted.emit()

func play_hurt_sound():
	# Play the hurt sound effect
	if hurt_audio_player:
		hurt_audio_player.play()

func set_depletion_active(active: bool):
	is_depleting = active

func get_hunger_percentage() -> float:
	return current_hunger / max_hunger

func is_starving() -> bool:
	return current_hunger <= min_hunger

func _sacrifice_firefly_for_hunger():
	"""Sacrifices a firefly to save the player from starvation"""
	if not firefly_manager:
		return

	# Play the light pop sound
	if firefly_sacrifice_audio_player:
		firefly_sacrifice_audio_player.play()

	# Sacrifice the firefly (triggers death animation)
	firefly_manager.lose_firefly()

	# Restore hunger to half
	current_hunger = max_hunger * 0.5
	hunger_changed.emit(current_hunger, max_hunger)

	# Update heartbeat after sacrifice
	_update_heartbeat()

func _update_heartbeat():
	"""Updates heartbeat sound based on current hunger level"""
	if not heartbeat_audio_player:
		return

	# Don't play heartbeat if player is dead
	if death_manager and death_manager.is_dead:
		if is_heartbeat_playing:
			heartbeat_audio_player.stop()
			is_heartbeat_playing = false
		return

	# Check if hunger is below threshold
	var should_play_heartbeat = current_hunger <= heartbeat_threshold

	if should_play_heartbeat and not is_heartbeat_playing:
		# Start playing heartbeat
		heartbeat_audio_player.play()
		is_heartbeat_playing = true
	elif not should_play_heartbeat and is_heartbeat_playing:
		# Stop playing heartbeat
		heartbeat_audio_player.stop()
		is_heartbeat_playing = false

func stop_heartbeat():
	"""Stops the heartbeat sound (called on death)"""
	if heartbeat_audio_player and is_heartbeat_playing:
		heartbeat_audio_player.stop()
		is_heartbeat_playing = false

extends Node

## Global hit stop / freeze frame manager
## Call HitStop.activate(duration) from anywhere to pause the game briefly

var time_scale_before: float = 1.0
var is_active: bool = false

func activate(duration: float = 0.08):
	"""Freeze the game for a brief moment to add impact feedback"""
	if is_active:
		return  # Don't stack hit stops

	is_active = true
	time_scale_before = Engine.time_scale
	Engine.time_scale = 0.0

	# Use get_tree().create_timer with process_always flag
	# This timer runs even when time_scale is 0
	await get_tree().create_timer(duration, true, false, true).timeout

	Engine.time_scale = time_scale_before
	is_active = false

extends Node

# Signals
signal hunger_changed(current: float, maximum: float)
signal hunger_depleted()
signal food_consumed(amount: float)

# Configuration
@export var max_hunger: float = 100.0
@export var depletion_rate: float = 5.0  # Hunger lost per second
@export var min_hunger: float = 0.0

# State
var current_hunger: float = 100.0
var is_depleting: bool = true

func _ready():
	current_hunger = max_hunger
	hunger_changed.emit(current_hunger, max_hunger)

func _process(delta):
	if is_depleting:
		_deplete_hunger(delta)

func _deplete_hunger(delta: float):
	if current_hunger > min_hunger:
		current_hunger -= depletion_rate * delta
		current_hunger = max(current_hunger, min_hunger)
		hunger_changed.emit(current_hunger, max_hunger)

		if current_hunger <= min_hunger:
			hunger_depleted.emit()

func consume_food(amount: float):
	current_hunger = min(current_hunger + amount, max_hunger)
	hunger_changed.emit(current_hunger, max_hunger)
	food_consumed.emit(amount)

func take_damage(amount: float):
	# Reduce hunger when taking damage
	current_hunger = max(current_hunger - amount, min_hunger)
	hunger_changed.emit(current_hunger, max_hunger)

	# Check if hunger depleted
	if current_hunger <= min_hunger:
		hunger_depleted.emit()

func set_depletion_active(active: bool):
	is_depleting = active

func get_hunger_percentage() -> float:
	return current_hunger / max_hunger

func is_starving() -> bool:
	return current_hunger <= min_hunger

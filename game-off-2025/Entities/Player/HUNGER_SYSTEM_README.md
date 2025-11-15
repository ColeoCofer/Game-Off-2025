# Hunger System

## Overview
The bat has a hunger system that constantly depletes over time. The bat must find and eat butterflies to survive.

## Components

### HungerManager (HungerManager.gd)
Located in `Entities/Player/HungerManager.gd`

**Properties:**
- `max_hunger`: Maximum hunger value (default: 100.0)
- `depletion_rate`: How much hunger depletes per second (default: 5.0)
- `current_hunger`: Current hunger level

**Signals:**
- `hunger_changed(current, maximum)`: Emitted when hunger changes
- `hunger_depleted()`: Emitted when hunger reaches zero
- `food_consumed(amount)`: Emitted when the bat eats food

**Methods:**
- `consume_food(amount)`: Restores hunger by the specified amount
- `set_depletion_active(active)`: Enable/disable hunger depletion
- `get_hunger_percentage()`: Returns hunger as a percentage (0.0 to 1.0)
- `is_starving()`: Returns true if hunger is at minimum

### HungerUI (UI/HungerUI.gd)
Visual hunger bar that displays below the stamina bar.

**Colors:**
- Green: Above 50% hunger
- Yellow: Between 25-50% hunger (warning)
- Red: Below 25% hunger (critical)

### Butterfly Entity (Entities/Bugs/butterfly.gd)
Collectible food items for the bat.

**Properties:**
- `hunger_restore_amount`: How much hunger is restored (default: 20.0)
- `hover_amplitude`: Vertical hover distance (default: 3.0)
- `hover_speed`: Speed of hovering animation (default: 2.0)
- `fade_out_duration`: How long the collection animation takes (default: 0.3)

**Behavior:**
- Butterflies gently bob up and down
- When the player collides with a butterfly, it restores hunger and fades out
- Butterflies detect the player through the PlatformerController2D class

## Usage

### Adding Butterflies to a Level
1. Instance the `butterfly.tscn` scene from `Entities/Bugs/`
2. Position it in your level
3. Adjust properties as needed (hunger restore amount, hover settings, etc.)

### Adjusting Hunger Depletion
In the Player scene or level, select the HungerManager node and adjust:
- `depletion_rate`: Higher = faster hunger depletion
- `max_hunger`: Total hunger capacity

### Game Over on Starvation
To implement game over when the bat starves, connect to the `hunger_depleted` signal:

```gdscript
func _ready():
	var hunger_manager = $Player/HungerManager
	hunger_manager.hunger_depleted.connect(_on_player_starved)

func _on_player_starved():
	# Handle game over
	print("Game Over - Bat starved!")
```

## Integration with Existing Systems
- The hunger system works alongside the existing stamina/echolocation system
- Both UI bars are displayed in the top-left corner
- Hunger constantly depletes, adding survival pressure to the gameplay

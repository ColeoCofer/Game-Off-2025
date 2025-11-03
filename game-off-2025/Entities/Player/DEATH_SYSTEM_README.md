# Death System

## Overview
When the bat's hunger depletes completely, a dramatic death animation plays followed by a game over menu.

## Components

### DeathManager (DeathManager.gd)
Located in `Entities/Player/DeathManager.gd`

Handles the death sequence when hunger reaches zero.

**Properties:**
- `death_animation_duration`: How long the death animation takes (default: 2.0 seconds)
- `rotation_speed`: How many full rotations during death (default: 3.0)
- `fall_speed`: How far the player falls during death (default: 100.0 pixels)

**Behavior:**
1. Listens for the `hunger_depleted` signal from HungerManager
2. Disables player physics/control
3. Applies death shader to the player sprite
4. Plays death animation (rotation, shrinking, falling)
5. Shows the death menu when animation completes

### Death Shader (death_shader.gdshader)
Located in `Shaders/death_shader.gdshader`

A visual shader that creates a dramatic death effect.

**Effects:**
- Fades the player to black
- Adds wave distortion
- Creates chromatic aberration (color separation)
- Reduces opacity for a dissolve effect

**Parameters:**
- `death_progress`: Animated from 0.0 to 1.0 during death
- `distortion_strength`: How much wave distortion to apply (default: 0.5)
- `death_color`: Color to fade to (default: black)

### Death Menu (UI/death_menu.tscn)
The game over screen displayed after death.

**UI Elements:**
- Title: "YOU STARVED"
- Subtitle: "The bat ran out of energy..."
- Play Again button: Reloads the current scene
- Exit button: Quits the game

**Script (DeathMenu.gd):**
- `show_menu()`: Fades in the menu
- Signals: `play_again_pressed`, `exit_pressed`

## How It Works

### Death Sequence
1. **Hunger depletes to zero**
   - HungerManager emits `hunger_depleted` signal

2. **Death triggered**
   - DeathManager receives signal
   - Player physics disabled
   - Death shader applied to sprite

3. **Animation plays** (2 seconds)
   - Player rotates 3 full times
   - Shrinks to 30% size
   - Falls 100 pixels
   - Shader fades to black with distortion

4. **Menu appears**
   - Death menu fades in
   - Player can choose to restart or quit

## Customization

### Adjusting Death Animation
In the Player scene, select the DeathManager node:
- `death_animation_duration`: Make it faster/slower
- `rotation_speed`: More/fewer spins
- `fall_speed`: How far the bat drops

### Modifying Visual Effects
Edit `Shaders/death_shader.gdshader`:
- Change `death_color` for different fade colors
- Adjust distortion formulas for different effects
- Modify chromatic aberration threshold

### Customizing Death Menu
Edit `UI/death_menu.tscn`:
- Change text messages
- Modify button styling
- Adjust colors and fonts
- Add additional options

## Testing
To test the death system quickly:
1. In HungerManager, set `max_hunger` to a low value (e.g., 10.0)
2. Set `depletion_rate` high (e.g., 20.0)
3. Run the game and watch the bat die quickly

## Integration
The death system is fully integrated:
- Automatically connected to HungerManager
- No additional setup required
- Works out of the box when hunger reaches zero

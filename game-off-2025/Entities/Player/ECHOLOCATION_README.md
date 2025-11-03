# Echolocation Vision System

A shader-based visibility system for your bat platformer where the player has limited vision and uses echolocation to reveal the level with an expanding wave effect.

## How It Works

### 1. Limited Vision
- The bat can only see a small radius (~75 pixels) around itself
- Everything outside this radius is covered in darkness (95% black)
- The vision circle has a smooth gradient fade (no harsh edges)

### 2. Echolocation Mechanic with Expanding Wave
- Press the **E key** to emit an echolocation pulse
- The pulse **expands outward** like a real sound wave at 1200 pixels/second
- Areas are revealed as the wave passes through them
- Revealed areas remain visible and then fade out over 3.5 seconds
- The wave creates a realistic "sonar ping" effect

### 3. Cooldown System
- After using echolocation, there's a 5-second cooldown
- A cooldown bar shows when echolocation is ready again
- Only one echolocation can be active during cooldown, but multiple fading pulses can overlap

## Files

### Core System
- `EcholocationManager.gd` - Main script managing vision, echolocation waves, and cooldown
- `vision_shader.gdshader` - Custom shader creating darkness, vision circle, and expanding wave effects
- `CooldownUI.gd` - UI script for displaying echolocation cooldown

### Integration
- Added to player as a CanvasLayer node
- Shader applied via ColorRect overlay
- Cooldown UI displayed in top-left corner

## Customization

All parameters can be adjusted in the Godot Inspector by selecting the EcholocationManager node.

### Vision Settings

#### Vision Radius
```gdscript
@export var vision_radius: float = 75.0
```
How far the bat can see around itself in pixels.

#### Vision Fade Distance
```gdscript
@export var vision_fade_distance: float = 40.0
```
Controls the gradient fade at the edge of the vision circle.
- Higher values = softer, more gradual fade
- Lower values = sharper transition to darkness
- 0 = instant cutoff (harsh edge)

Example: With `vision_radius = 75.0` and `vision_fade_distance = 40.0`:
- Fully visible from 0-35 pixels
- Gradual fade from 35-75 pixels
- Fully dark beyond 75 pixels

#### Darkness Intensity
```gdscript
@export var darkness_intensity: float = 0.95
```
How dark the unrevealed areas are (0.0 = no darkness, 1.0 = completely black).

### Echolocation Wave Settings

#### Echo Reveal Distance
```gdscript
@export var echo_reveal_distance: float = 800.0
```
Maximum distance the echolocation wave can reveal (in pixels).

#### Echo Expansion Speed ⚡ NEW!
```gdscript
@export var echo_expansion_speed: float = 1200.0
```
How fast the echolocation wave expands outward (pixels per second).

**Examples:**
- **600.0** - Slow expansion (~1.3 seconds to reach 800px)
- **1200.0** (default) - Medium speed (~0.67 seconds)
- **2400.0** - Fast expansion (~0.33 seconds)
- **4800.0** - Nearly instant reveal

**Tip:** Slower speeds (600-1000) create a more dramatic wave effect, while faster speeds (2000+) feel more responsive.

#### Echo Fade Duration
```gdscript
@export var echo_fade_duration: float = 3.5
```
How long revealed areas stay visible before fading to black (in seconds).

#### Echolocation Cooldown
```gdscript
@export var echolocation_cooldown: float = 5.0
```
Time in seconds before echolocation can be used again.

### Shader Wave Settings

In `vision_shader.gdshader`, you can also adjust:

#### Wave Thickness
```glsl
uniform float wave_thickness = 100.0;
```
This parameter exists but isn't currently used in the reveal logic. You can customize the shader to add a visible wave ring if desired.

## Technical Details

### How the Expanding Wave Works

1. **Pulse Creation**: When you press E, a new pulse is created at the player's position with `radius = 0.0`
2. **Expansion**: Each frame, the radius increases by `echo_expansion_speed * delta`
3. **Reveal Logic**: The shader only reveals pixels where `distance_to_pulse <= current_radius`
4. **Fade Out**: As time passes, `intensity` decreases, making revealed areas gradually darken
5. **Cleanup**: Once intensity reaches 0, the pulse is removed

### Performance

- Shader runs on GPU (very efficient)
- Supports up to 10 simultaneous echolocation pulses
- Arrays automatically managed (old pulses removed)
- Real-time radius updates every frame

### Math Behind the Wave

The expansion formula:
```
radius(t) = echo_expansion_speed × time_elapsed
```

Example with default settings:
- At t=0.0s: radius = 0px (just emitted)
- At t=0.5s: radius = 600px (halfway across screen)
- At t=0.67s: radius = 800px (max reveal distance reached)

## Tips for Level Design

1. **Speed Balance**: Match `echo_expansion_speed` to your level's platforming pace
2. **Platforming Challenges**: Design jumps that require timing echolocation with the cooldown
3. **Visual Pacing**: Slower expansion speeds create more tension and atmosphere
4. **Audio Sync**: Consider adding sound effects that match the expansion speed
5. **Cooldown Management**: Design sections that require strategic echolocation use

## Customization Examples

### Quick, Responsive Echolocation
```gdscript
echo_expansion_speed = 3000.0  # Very fast
echolocation_cooldown = 2.0    # Short cooldown
echo_fade_duration = 2.0       # Quick fade
```

### Dramatic, Strategic Echolocation
```gdscript
echo_expansion_speed = 600.0   # Slow wave
echolocation_cooldown = 8.0    # Long cooldown
echo_fade_duration = 5.0       # Longer visibility
```

### Sonar-Like Precision
```gdscript
echo_expansion_speed = 1800.0  # Medium-fast
echo_reveal_distance = 600.0   # Shorter range
vision_radius = 50.0           # Smaller vision circle
```

## Troubleshooting

### Wave expands too slowly/quickly
Adjust `echo_expansion_speed` in the Inspector. Remember:
- Higher = faster expansion
- At 800px reveal distance: speed of 1200 takes ~0.67 seconds

### Areas don't reveal at all
- Check that `echo_radii` array is being passed to the shader in `update_echo_shader_params()`
- Verify the pulse `radius` is increasing in `update_echo_pulses()`

### Everything reveals instantly
- Your `echo_expansion_speed` might be set too high (>5000)
- Try reducing it to 800-1500 for visible expansion

## Future Enhancements

Potential additions:
1. **Visible Wave Ring** - Add a bright ring at the wave front
2. **Wave Audio** - Sync sound effects with wave expansion
3. **Variable Speed** - Change speed based on environment (slower in water, etc.)
4. **Wave Obstacles** - Objects that block echolocation waves
5. **Directional Echolocation** - Aim the wave in a specific direction

---

**Created for Game Off 2025** - Expanding wave feature added for realistic sonar effect!

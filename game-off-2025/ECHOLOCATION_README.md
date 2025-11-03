# Echolocation Vision System

This system implements a bat-themed visibility mechanic where the player has limited vision and uses echolocation to temporarily reveal the level.

## How It Works

### 1. Limited Vision
- The bat can only see a small radius (~75 pixels) around itself
- Everything outside this radius is covered in darkness (95% black)
- The darkness overlay follows the player using a custom shader

### 2. Echolocation Mechanic
- Press the **E key** to emit an echolocation pulse
- Each pulse reveals platforms and terrain within ~800 pixels
- Revealed areas fade out over 3.5 seconds
- Multiple pulses can be active simultaneously

### 3. Stamina System
- You have 5 charges of echolocation
- Each pulse uses 1 charge
- After 1 second of not using echolocation, charges regenerate at 0.5 per second
- Stamina is displayed in the top-left corner as white boxes

## Files Created

### Core System
- `vision_shader.gdshader` - Custom shader that creates darkness and vision effects
- `EcholocationManager.gd` - Main script managing vision, echolocation, and stamina
- `StaminaUI.gd` - UI script for displaying stamina charges

### Modified Files
- `level-1.tscn` - Added EcholocationManager CanvasLayer with UI
- `project.godot` - Added "echolocate" input mapping (E key)

## Customization

### Adjust Vision Radius
In `EcholocationManager.gd`:
```gdscript
@export var vision_radius: float = 75.0  # Change this value
```

Or in Godot editor:
1. Select "EcholocationManager" node in Level1 scene
2. Adjust "Vision Radius" in Inspector

### Adjust Vision Fade Distance
Control how gradually the vision fades to darkness (new feature!):
```gdscript
@export var vision_fade_distance: float = 40.0  # Higher = more gradual fade
```

**How it works:**
- The fade starts at `(vision_radius - vision_fade_distance)` pixels
- Gradually darkens until completely black at `vision_radius` pixels
- Creates a smooth gradient instead of a harsh circle edge

**Examples:**
- **40.0** (default) - Smooth, gradual fade (starts fading at 35px, fully dark at 75px)
- **10.0** - Quick, sharper fade to darkness (fades between 65-75px)
- **60.0** - Very gradual, soft fade (starts fading at 15px)
- **0.0** - Instant cutoff (harsh edge, no fade)

This creates a much more atmospheric effect with no harsh edge!

### Change Darkness Intensity
In `EcholocationManager.gd`:
```gdscript
@export var darkness_intensity: float = 0.95  # 0.0 = no darkness, 1.0 = complete black
```

### Modify Echolocation Range
In `EcholocationManager.gd`:
```gdscript
@export var echo_reveal_distance: float = 800.0  # How far echolocation reveals
```

### Adjust Fade Duration
In `EcholocationManager.gd`:
```gdscript
@export var echo_fade_duration: float = 3.5  # Seconds before reveal fades completely
```

### Change Stamina Settings
In `EcholocationManager.gd`:
```gdscript
@export var max_stamina: int = 5  # Maximum charges
@export var stamina_regen_delay: float = 1.0  # Seconds before regen starts
@export var stamina_regen_rate: float = 0.5  # Charges per second
```

### Change Echolocation Key
In `project.godot`, find the `echolocate` input action and change the keycode:
- Current: 69 (E key)
- Common alternatives:
  - 32 (Spacebar) - Note: conflicts with jump
  - 70 (F key)
  - 81 (Q key)
  - 4194326 (Right Shift)

Or use the Godot editor:
1. Project → Project Settings → Input Map
2. Find "echolocate" action
3. Click the key binding and press your desired key

## Technical Details

### Shader System
The `vision_shader.gdshader` uses:
- **Player position** - Updated every frame in screen coordinates
- **Vision circle** - Smoothstep falloff for clean edges
- **Echo arrays** - Supports up to 10 simultaneous echolocation pulses
- **Alpha blending** - Combines vision and echo effects

### Screen Space Conversion
The system converts world positions to screen space accounting for:
- Camera position
- Camera zoom (3.5x in your setup)
- Viewport size

### Performance
- Shader runs on GPU (very efficient)
- Arrays limited to 10 echolocation pulses maximum
- Faded pulses automatically removed from array

## Tips for Level Design

1. **Use Contrast** - Since the game is dark, ensure platforms are bright/white
2. **Test Visibility** - Make sure the 75px vision radius gives players enough immediate awareness
3. **Platforming Challenges** - Design jumps that require echolocation to see landing platforms
4. **Stamina Management** - Create sections that require careful stamina usage
5. **Audio Feedback** - Consider adding sound effects for echolocation pulses

## Troubleshooting

### Everything is completely dark
- Check that `darkness_intensity` is not set to 1.0
- Verify the shader is loaded correctly in `EcholocationManager._ready()`

### Echolocation doesn't work
- Ensure the "echolocate" input is configured in project.godot
- Check that `can_use_echolocation()` returns true (requires stamina >= 1.0)
- Verify shader arrays are being updated in `update_echo_shader_params()`

### Vision circle doesn't follow player
- Check that the player node path is correct in `EcholocationManager.gd`:
  ```gdscript
  @onready var player: CharacterBody2D = get_node("/root/Level1/Player")
  ```
- Verify camera reference is valid

### Stamina UI not showing
- Check that StaminaUI node is a child of EcholocationManager
- Verify the signal connection in `StaminaUI._ready()`

## Future Enhancements

Potential improvements you could add:
1. **Audio** - Add echolocation "ping" sound effects
2. **Visual Pulse** - Expanding circle animation when echolocation activates
3. **Upgrades** - Collectibles that increase max stamina or reveal distance
4. **Different Modes** - Varying echolocation ranges based on context
5. **Enemies** - Creatures revealed only during echolocation
6. **Hazards** - Obstacles that become visible with echolocation

## Credits

System implemented for Game Off 2025
- Shader-based vision system
- Stamina management
- Real-time echolocation reveal/fade

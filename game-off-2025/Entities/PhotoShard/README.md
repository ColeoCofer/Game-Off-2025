# Photo Shard Object

A collectible photo shard piece that appears in cutscenes and levels. Features glowing and bobbing animations.

## Scene Structure

- **PhotoShard** (Area2D) - Main node with collision detection
  - **Sprite2D** - Displays the photo shard sprite from sona-sprite-sheet.png
  - **CollisionShape2D** - CircleShape2D for player interaction
  - **PointLight2D** - Warm glow effect (yellowish/paper color)

## Features

### Visual Effects
- **Bobbing Animation**: Gentle up-and-down floating motion (4px amplitude, 2Hz frequency)
- **Pulsing Glow**: Warm yellowish light that pulses rhythmically (30% intensity variation)
- **Spawn Animation**: Fades in while floating down over 0.8 seconds
- **Collection Animation**: Bright flash, scales up 1.8x, floats upward, and fades out over 0.6 seconds

### Signals
- `photo_shard_collected` - Emitted when player collects the shard

## Export Parameters

### Animation Settings
- `hover_amplitude: float = 4.0` - Height of bobbing motion in pixels
- `hover_speed: float = 2.0` - Speed of bobbing oscillation (Hz)
- `glow_energy: float = 2.5` - Base brightness of the glow effect
- `glow_pulse_speed: float = 2.0` - Speed of glow pulsing (Hz)
- `fade_out_duration: float = 0.6` - Duration of collection animation
- `spawn_animation_duration: float = 0.8` - Duration of spawn animation

## Usage

### Basic Placement in Level
Simply add the `photo_shard.tscn` to your level. It will automatically bob and glow.

### With Spawn Animation
```gdscript
var photo_shard = preload("res://Entities/PhotoShard/photo_shard.tscn").instantiate()
add_child(photo_shard)
photo_shard.position = Vector2(100, 200)
photo_shard.play_spawn_animation()
```

### Listening for Collection
```gdscript
var photo_shard = $PhotoShard
photo_shard.photo_shard_collected.connect(_on_photo_shard_collected)

func _on_photo_shard_collected():
    print("Player collected the photo shard!")
    # Trigger cutscene, dialogue, etc.
```

### Integration with Cutscenes
The photo shard is designed to work with the CutsceneDirector system:
```gdscript
# In CutsceneDirector action
{
    "type": CutsceneDirector.ActionType.SPAWN_OBJECT,
    "scene_path": "res://Entities/PhotoShard/photo_shard.tscn",
    "position": Vector2(300, 200),
    "call_method": "play_spawn_animation"
}
```

## Technical Details

- **Scene Path**: `res://Entities/PhotoShard/photo_shard.tscn`
- **Script Path**: `res://Entities/PhotoShard/photo_shard.gd`
- **Sprite Region**: Rect2(16, 80, 16, 16) from sona-sprite-sheet.png
- **Collision Layer**: 0 (no collision with world)
- **Collision Detection**: Area2D monitoring for player CharacterBody2D

## Notes

- The photo shard uses a warm yellowish glow (Color(1, 0.9, 0.7)) to evoke a vintage photograph aesthetic
- Collection automatically disables collision and removes the node after animation
- The `is_bobbing` flag can be used to pause the bobbing animation when needed
- Designed specifically for the opening_cutscene where Sona discovers the photo shard

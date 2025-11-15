# Cave Entrance System

The cave entrance system provides a cinematic level completion sequence where the player character walks into a cave entrance with depth effects and screen fade.

## Overview

When the player approaches and enters the trigger area, the system:
1. Disables player input
2. Automatically walks the player toward the entrance point
3. Scales the player down to simulate walking into the distance
4. Fades the player sprite to create depth effect
5. Fades the screen to black
6. Triggers level completion

## Setup in Godot Editor

### Adding Cave Entrance to a Level

1. **Instance the Scene**
   - Open your level in Godot
   - Navigate to `Entities/LevelComplete/cave_entrance.tscn`
   - Drag it into your level scene
   - Position it where you want the exit to be

2. **Replace the Placeholder Sprite**
   - Select the `CaveEntrance` node
   - Expand to find the `EntranceSprite` child node
   - In the Inspector, find the `Texture` property
   - Replace with your cave entrance sprite from your sprite sheet
   - Adjust `scale`, `position`, and `offset` as needed to match your level art

3. **Adjust the Trigger Area**
   - Select `CaveEntrance > TriggerArea > CollisionShape2D`
   - Resize the collision shape to match the size of your cave entrance
   - Position it at the entrance location (the player will walk toward the center of this area)
   - The player will automatically walk toward the trigger area center once they enter it

4. **Configure Animation Parameters** (Optional)
   - Select the root `CaveEntrance` node
   - In the Inspector, adjust these export variables:
     - `walk_duration`: How long the walk animation takes (default: 1.5s)
     - `scale_duration`: How long the shrink/fade effect takes (default: 1.2s)
     - `fade_to_black_duration`: Screen fade time (default: 0.8s)
     - `min_player_scale`: Final scale of player (default: 0.25 = 25% size)
     - `depth_offset`: How far "back" (Y axis) player walks into cave (default: 20.0)

## Node Structure

```
CaveEntrance (Node2D)
├── EntranceSprite (Sprite2D)          # Your cave entrance artwork
├── TriggerArea (Area2D)               # Detects player entry
│   └── CollisionShape2D               # Trigger collision shape
└── VisualHelper (ColorRect)           # Editor-only helper (hidden at runtime)
```

## Animation Sequence Details

### Phase 1: Walk to Entrance (1.5s default)
- Player input is disabled
- Player automatically walks to the center of the trigger area
- Adds a small Y-axis offset (`depth_offset`) to simulate walking "back" into the cave
- Uses smooth tween animation

### Phase 2: Depth Effect (1.2s default)
- Player scales down from 100% → 25% (configurable)
- Player sprite fades from opaque → transparent
- Both effects run in parallel for realism

### Phase 3: Screen Fade (0.8s default)
- Black overlay fades in across entire screen
- After fade completes, level completion triggers
- Success menu appears

## Tips for Best Results

1. **Trigger Area Sizing**: Make the trigger area match the size of your cave entrance. The player will walk toward its center, so size and position it to represent the entrance opening.

2. **Depth Offset**: Adjust `depth_offset` to control how far "back" (Y-axis) the player walks. A value of 20 gives a subtle depth effect. Increase for more pronounced effect.

3. **Visual Coordination**: Make sure your cave entrance sprite is dark enough that the player naturally fades into it. The default scale goes down to 25%, simulating walking into the distance.

4. **Timing Tweaks**:
   - Faster paced: Reduce all duration values by 0.3-0.5s
   - More cinematic: Increase walk_duration to 2.0s and scale_duration to 1.5s

## Replacing Old LevelCompleteArea

To replace an existing `LevelCompleteArea` with the new cave entrance:

1. Delete the old `LevelCompleteArea` node from your level
2. Instance `cave_entrance.tscn` at the same location
3. Add your cave sprite to the `EntranceSprite` node
4. Test the animation timing and adjust as needed

## Troubleshooting

**Player doesn't animate:**
- Check that the player is in the "Player" group
- Verify trigger_area is assigned in the CaveEntrance script (should auto-assign via NodePath)
- Check collision layers/masks on TriggerArea

**Animation looks wrong:**
- Adjust `depth_offset` to control how far "back" the player walks
- Fine-tune the timing values (`walk_duration`, `scale_duration`)
- Make sure player AnimatedSprite2D is named exactly "AnimatedSprite2D"
- Ensure trigger area is positioned at the entrance center, not offset

**Fade doesn't cover screen:**
- The fade overlay uses viewport size automatically
- If issues occur, check that no other UI is blocking it (layer 200 should be on top)

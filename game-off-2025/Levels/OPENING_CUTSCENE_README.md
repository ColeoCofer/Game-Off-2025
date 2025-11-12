# Opening Cutscene Implementation

Complete implementation of the game's opening cutscene sequence.

## Overview

The opening cutscene consists of:
1. Fade into level-1 (handled by SceneManager)
2. Sona walks slowly and stops
3. Dialogue: "I should turn around..."
4. Sona walks forward a few more steps
5. Photo shard appears at screen edge
6. Dialogue: "Huh...?"
7. Sona walks to photo shard and picks it up
8. Fullscreen cutscene showing photo memories
9. Fade to black with final dialogue
10. Transition to title screen with music

## Files Created

- `Levels/opening_cutscene.gd` - Main cutscene orchestration script
- `Entities/PhotoShard/photo_shard.tscn` - Photo shard entity
- `Entities/PhotoShard/photo_shard.gd` - Photo shard script with animations

## Integration Steps

### Option 1: Add to Existing Level-1

1. **Open level-1.tscn in Godot**

2. **Add opening cutscene script:**
   - Select the root node of level-1
   - Add a child Node (not Node2D)
   - Name it "OpeningCutscene"
   - Attach the script `opening_cutscene.gd` to it

3. **Ensure player is in "player" group:**
   - Select the Player node
   - In the Inspector, go to Node tab
   - Under Groups, ensure "player" group is added

4. **Test:**
   - Run level-1 (F6)
   - The cutscene should auto-start after 1 second
   - Player control will be disabled during sequence

### Option 2: Create New Opening Scene

If you want a dedicated opening scene:

1. **Create new scene:**
   - Scene → New Scene
   - Add Node2D as root
   - Name it "OpeningScene"

2. **Add required elements:**
   - Add your level background/tilemap
   - Instance the Player scene
   - Add lighting, effects, etc.

3. **Add cutscene script:**
   - Add child Node to root
   - Attach `opening_cutscene.gd`

4. **Set as first scene:**
   - In `project.godot`, change `run/main_scene` to this scene
   - Or update your main menu to load this scene first

## Customization

### Adjusting Walk Distances

Edit `opening_cutscene.gd`:

```gdscript
# Change these values to adjust how far Sona walks
var walk_distance_1 = 80.0  # First walk
var walk_distance_2 = 50.0  # Second walk (after dialogue)
```

### Changing Walk Speed

```gdscript
# Adjust the second parameter (speed in pixels/second)
actions.append(CutsceneDirector.action_player_walk(target_x, 40.0))
# Change 40.0 to make Sona walk faster or slower
```

### Adding Photo Shard Texture

Currently the photo shard uses a placeholder. To add real art:

1. **Import your photo shard image** to `Assets/Art/`
2. **Edit `photo_shard.tscn`:**
   - Select the Sprite2D node
   - In Inspector, set Texture to your image
3. **Remove placeholder code:**
   - In `photo_shard.gd`, comment out `_create_placeholder_texture()`

### Customizing Dialogue

Edit the dialogue arrays in `opening_cutscene.gd`:

```gdscript
actions.append(CutsceneDirector.action_dialogue([
    "Your custom dialogue here...",
    "Second line if needed"
]))
```

### Changing Cutscene Images

Edit `create_photo_cutscene_frames()` to use different images:

```gdscript
frames.append(CutscenePlayerScript.create_frame(
    "res://path/to/your/image.png",
    ["Your dialogue here"]
))
```

## Adding Sound Effects (Phase 5)

When you implement Phase 5 (Audio & Polish), you can add sounds:

```gdscript
# In opening_cutscene.gd, add sound actions:
actions.append(CutsceneDirector.action_custom(play_footstep_sound))
actions.append(CutsceneDirector.action_custom(play_shard_pickup_sound))

func play_footstep_sound():
    # Your audio code here
    pass

func play_shard_pickup_sound():
    # Your audio code here
    pass
```

## Troubleshooting

### Cutscene doesn't start
- Check console for errors
- Ensure player is in "player" group
- Verify `opening_cutscene.gd` is attached to a node in the scene

### Player doesn't walk
- Check that CutsceneDirector found the player (console message)
- Ensure player has `UltimatePlatformerController` with control methods
- Verify walk target positions are different from start position

### Photo shard doesn't appear
- Check that `photo_shard.tscn` exists at correct path
- Look for errors in console about scene loading
- The placeholder should appear as a yellowish rectangle

### Cutscene plays but player can still move
- Ensure `control_enabled` flag was added to player controller
- Check that `disable_control()` method exists
- Verify no other scripts are overriding control

### Transition to title screen fails
- Ensure `res://UI/MainMenu.tscn` path is correct
- Check that SceneManager is working properly
- Look for scene loading errors in console

## Testing Checklist

- [ ] Cutscene auto-starts when level loads
- [ ] Player control is disabled
- [ ] Sona walks at correct speed
- [ ] First dialogue appears: "I should turn around..."
- [ ] Sona takes additional steps forward
- [ ] Photo shard spawns and is visible
- [ ] Second dialogue appears: "Huh...?"
- [ ] Sona walks to photo shard
- [ ] Pickup animation plays
- [ ] Fullscreen cutscene starts
- [ ] All photo images display correctly
- [ ] All dialogue displays correctly
- [ ] Can advance through dialogue with Space
- [ ] Final image with "Maybe there's another way..."
- [ ] Transitions to title screen
- [ ] Background music starts (if implemented)
- [ ] Player control is restored (if continuing to gameplay)

## Next Steps

After the opening cutscene is working:

1. **Add echolocation tutorial** (Phase 6) - Show tooltip after first butterfly
2. **Implement ending cutscene** (Phase 8) - Similar structure to opening
3. **Add audio polish** (Phase 5) - Footsteps, pickup sounds, music transitions
4. **Fine-tune timing** - Adjust pauses and walk speeds for best feel

## Notes

- The opening cutscene uses all systems from Phases 1-4
- Player position should be carefully set in level-1 for proper walk distances
- Consider adding a "Skip Cutscene" option for replaying (hold ESC)
- The photo shard placeholder can be replaced with actual art asset
- Music transition happens via BackgroundMusic autoload (configure as needed)

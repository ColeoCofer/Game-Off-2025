# Quick Start: Adding Checkpoints to Your Levels

## Step 1: Add a Checkpoint to a Level

1. Open a level scene in Godot (e.g., `level-1.tscn`)
2. Click the "+" button to instantiate a scene
3. Navigate to `res://Entities/Objects/checkpoint.tscn`
4. Position the checkpoint where you want players to respawn
5. Save the level

That's it! The checkpoint will automatically work.

## Step 2: Test the Checkpoint

### Testing in Debug Mode (Recommended)
1. Enable debug mode in your game (check DebugManager settings)
2. Run to the level and pass the checkpoint
3. Intentionally fall into a pit (trigger fall death)
4. You should respawn at the checkpoint instead of the level start

### Testing in Normal Mode
1. Run to the level and pass the checkpoint
2. Die (run out of hunger, hit a hazard, etc.)
3. Click "Play Again" in the death menu
4. You'll start at the beginning (checkpoint is cleared on restart)

## Step 3: Replace Placeholder Visuals (Optional)

The checkpoint currently uses a simple gradient placeholder. To make it look like a torch:

### Create Your Art
You'll need two sprites:
- **Unlit torch** - A torch without a flame (gray/dark)
- **Lit torch** - A torch with animated flames (bright, warm colors)

### Update the Scene
1. Open `checkpoint.tscn` in Godot
2. Select the `Sprite2D` node
3. In the Inspector, change the Texture to your torch sprite
4. (Advanced) Convert to AnimatedSprite2D for animated flames

### Recommended Sprite Sizes
- 16x32 pixels (fits with your existing pixel art style)
- Or 16x24 if you want a smaller torch

## Common Issues

### Checkpoint doesn't activate
- Make sure the player is in the "Player" group
- Check the CollisionShape2D is the right size (default: 16x32)
- Verify the checkpoint's Area2D layer/mask settings

### Checkpoint still active after death
- This shouldn't happen - checkpoints reset on level reload
- If it does, check SceneManager.reload_current_level() is being called

### Multiple checkpoints in one level
- Currently only the most recently activated checkpoint is used
- This is intentional - players respawn at the furthest checkpoint reached

## Advanced: Customizing Checkpoint Behavior

### Change Detection Area Size
1. Open `checkpoint.tscn`
2. Select `CollisionShape2D`
3. Modify the `size` property (default: 16x32)

### Add Activation Sound
1. Find or create a torch ignition sound effect
2. Open `checkpoint.tscn`
3. Select the `AudioStreamPlayer` node
4. Assign your sound to the `stream` property

### Add Flame Particles
1. Open `checkpoint.tscn`
2. Select `GPUParticles2D`
3. Create a new ParticleProcessMaterial
4. Configure:
   - Direction: upward (angle: -90)
   - Initial velocity: 20-40
   - Colors: yellow/orange/red gradient
   - Lifetime: 0.5-1.0 seconds

### Adjust Light Glow
1. Open `checkpoint.tscn`
2. Select `PointLight2D`
3. Adjust:
   - `energy` for brightness (default: 1.5)
   - `texture_scale` for glow size (default: 2.0)
   - `color` for flame color (default: warm orange)

## Example: Typical Checkpoint Placement

Place checkpoints:
- After difficult platforming sections
- Before boss fights or major encounters
- At the midpoint of longer levels
- After collecting important items

Don't place checkpoints:
- Too frequently (reduces challenge)
- Right before the level end (not useful)
- In locations that would skip content

## Code Reference

If you need to interact with checkpoints programmatically:

```gdscript
# Get all checkpoints in the scene
var checkpoints = get_tree().get_nodes_in_group("checkpoint")

# Manually activate a checkpoint
checkpoint.activate()

# Check if checkpoint is activated
if checkpoint.activated:
    print("This checkpoint is lit!")

# Reset a checkpoint (make it unlit again)
checkpoint.reset()
```

## Integration with Other Systems

The checkpoint system integrates with:
- **DeathManager** - Uses checkpoint position in debug mode fall deaths
- **SceneManager** - Clears checkpoints on level change
- **CheckpointManager** - Automatically finds and connects to checkpoints

No additional setup required!

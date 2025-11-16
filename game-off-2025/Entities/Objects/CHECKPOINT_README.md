# Checkpoint System

## Overview
The checkpoint system allows players to respawn at checkpoints instead of the level start when they die. Checkpoints are memory-only (not saved to disk), so they reset when the player quits or restarts the level.

## Architecture

### Components
1. **Checkpoint** (`Entities/Objects/Checkpoint.gd`) - The checkpoint object that detects when the player passes it
2. **CheckpointManager** (`Entities/Player/CheckpointManager.gd`) - Player component that tracks the active checkpoint
3. **DeathManager** (`Entities/Player/DeathManager.gd`) - Uses checkpoint position when respawning in debug mode

### How It Works
1. Player runs past a checkpoint Area2D
2. Checkpoint activates (visual change, audio, particles)
3. Checkpoint emits `checkpoint_activated` signal with its position
4. CheckpointManager receives signal and stores the position
5. When player dies and restarts, CheckpointManager is reset (checkpoint cleared)
6. In debug mode, fall deaths respawn at checkpoint instead of level start

### Signal Flow
```
Checkpoint.body_entered
  → Checkpoint.activate()
    → checkpoint_activated signal
      → CheckpointManager._on_checkpoint_activated()
        → stores position in memory
```

## Usage

### Adding a Checkpoint to a Level
1. Instantiate `checkpoint.tscn` in your level
2. Position it where you want the respawn point
3. (Optional) Replace the placeholder visuals with your torch art
4. The CheckpointManager will automatically find and connect to it

### Creating Torch Visuals

The current checkpoint scene uses a simple placeholder. To add proper torch visuals:

1. **Create torch sprite sheets**:
   - `torch-unlit.png` - Torch without flame (single frame or idle animation)
   - `torch-lit.png` - Torch with flame (animated flames)

2. **Update the checkpoint scene**:
   - Replace the `Sprite2D` with an `AnimatedSprite2D`
   - Create two animations: "unlit" and "lit"
   - The checkpoint script will automatically play the correct animation

3. **Add particles** (optional):
   - Configure the `GPUParticles2D` node with flame particles
   - Set up a particle material with upward velocity and flame colors

4. **Add audio** (optional):
   - Add a torch ignition sound to the `AudioStreamPlayer`

### Example Scene Structure
```
Checkpoint (Area2D)
├── CollisionShape2D (detection area)
├── AnimatedSprite2D (torch visual)
├── PointLight2D (torch glow)
├── GPUParticles2D (flame particles)
└── AudioStreamPlayer (ignition sound)
```

## Configuration

### Checkpoint.gd Export Variables
- `activated` (bool) - Whether the checkpoint has been activated
- `activation_particles_scene` (PackedScene) - Optional one-shot particle effect on activation

### CheckpointManager
No export variables - works automatically

## Memory vs Persistence

**Checkpoints are memory-only:**
- Cleared when player dies and restarts the level
- Cleared when player quits and returns
- Cleared when player changes scenes

**Why?**
- You specified checkpoints should not persist between sessions
- This encourages full level completion in one run
- Prevents checkpoint camping/save scumming

## Debug Mode Behavior

In debug mode (when `DebugManager.debug_mode` is true):
- Fall deaths respawn at checkpoint instead of showing death menu
- This allows rapid iteration during level design
- Normal deaths still show death menu even in debug mode

## Future Enhancements

Possible improvements you could add:
- [ ] Multiple checkpoints per level (currently only tracks latest)
- [ ] Checkpoint save persistence (if you change your mind)
- [ ] Checkpoint UI indicator showing saved location
- [ ] Checkpoint deactivation (if you want to reset)
- [ ] Per-checkpoint difficulty modifiers

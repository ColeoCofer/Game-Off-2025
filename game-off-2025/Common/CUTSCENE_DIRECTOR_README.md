# CutsceneDirector System

Complete system for creating in-level cutscene sequences with scripted player movement, dialogue, and full-screen cutscenes.

## Components

### 1. CutsceneDirector (Autoload)
Global manager for in-level cutscene sequences.

### 2. CutsceneTrigger
Area2D-based trigger that starts cutscenes when player enters.

### 3. Player Control System
Methods added to player controller to disable/enable control during cutscenes.

## Quick Start

### Creating a Simple Cutscene

```gdscript
extends Node

func _ready():
    # Create cutscene actions
    var actions = []

    # Show dialogue
    actions.append(CutsceneDirector.action_dialogue([
        "I should turn around...",
        "Huh...?"
    ]))

    # Wait 1 second
    actions.append(CutsceneDirector.action_wait(1.0))

    # Make player walk to x position 500
    actions.append(CutsceneDirector.action_player_walk(500.0, 60.0))

    # More dialogue
    actions.append(CutsceneDirector.action_dialogue([
        "What's this?"
    ]))

    # Register and play
    CutsceneDirector.register_cutscene("opening", actions)
    CutsceneDirector.play_cutscene("opening")
```

### Using CutsceneTrigger in Levels

1. **Add trigger to level:**
   - Instance `Entities/CutsceneTrigger/cutscene_trigger.tscn`
   - Position where you want cutscene to trigger
   - Set `cutscene_id` in inspector (e.g., "level1_intro")

2. **Connect the trigger:**
```gdscript
extends Node2D

func _ready():
    # Find the trigger
    var trigger = $CutsceneTrigger
    trigger.cutscene_triggered.connect(_on_cutscene_triggered)

    # Register cutscene
    _register_level1_intro()

func _register_level1_intro():
    var actions = []
    actions.append(CutsceneDirector.action_dialogue(["Welcome to level 1!"]))
    CutsceneDirector.register_cutscene("level1_intro", actions)

func _on_cutscene_triggered(cutscene_id: String):
    CutsceneDirector.play_cutscene(cutscene_id)
```

## Available Actions

### Dialogue
Show dialogue using DialogueManager.

```gdscript
CutsceneDirector.action_dialogue([
    "Line 1 of dialogue",
    "Line 2 of dialogue"
])
```

### Wait
Pause for a duration.

```gdscript
CutsceneDirector.action_wait(2.0)  # Wait 2 seconds
```

### Player Walk
Move player to a specific x-position.

```gdscript
CutsceneDirector.action_player_walk(target_x, speed)
# Example: Walk to x=500 at 80 pixels/second
CutsceneDirector.action_player_walk(500.0, 80.0)
```

### Fullscreen Cutscene
Play a fullscreen cutscene with images.

```gdscript
var cutscene_player = preload("res://UI/CutscenePlayer/cutscene_player.tscn").instantiate()
var frames = []
frames.append(cutscene_player.create_frame(
    "res://Assets/Art/cut-scenes/sona-close-up-sad.png",
    ["Dialogue for this image"]
))

CutsceneDirector.action_fullscreen_cutscene(frames)
```

### Custom Function
Call any custom function.

```gdscript
CutsceneDirector.action_custom(my_custom_function)

func my_custom_function():
    print("Custom action executed!")
    # Spawn particle effect, play sound, etc.
```

## Complete Example: Opening Cutscene

```gdscript
extends Node2D

func _ready():
    # Wait for level to load
    await get_tree().create_timer(0.5).timeout

    # Create opening cutscene
    create_opening_cutscene()

    # Connect trigger
    var trigger = $CutsceneTrigger
    if trigger:
        trigger.cutscene_triggered.connect(_on_cutscene_start)

func create_opening_cutscene():
    var actions = []

    # 1. Sona walks slowly
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var walk_target = player.global_position.x + 100
        actions.append(CutsceneDirector.action_player_walk(walk_target, 40.0))

    # 2. Dialogue
    actions.append(CutsceneDirector.action_dialogue([
        "I should turn around..."
    ]))

    # 3. Pause
    actions.append(CutsceneDirector.action_wait(1.0))

    # 4. Walk forward more
    if player:
        var walk_target2 = player.global_position.x + 50
        actions.append(CutsceneDirector.action_player_walk(walk_target2, 40.0))

    # 5. Photo shard appears (custom function)
    actions.append(CutsceneDirector.action_custom(spawn_photo_shard))

    # 6. Dialogue
    actions.append(CutsceneDirector.action_dialogue(["Huh...?"]))

    # 7. Walk to photo shard
    actions.append(CutsceneDirector.action_player_walk(800.0, 60.0))

    # 8. Pickup animation (custom function)
    actions.append(CutsceneDirector.action_custom(pickup_photo_shard))

    # 9. Fullscreen cutscene
    var cutscene_frames = create_photo_cutscene_frames()
    actions.append(CutsceneDirector.action_fullscreen_cutscene(cutscene_frames))

    # Register
    CutsceneDirector.register_cutscene("opening", actions)

func spawn_photo_shard():
    print("Spawning photo shard...")
    # Your code to spawn the shard

func pickup_photo_shard():
    print("Picking up photo shard...")
    # Your code for pickup animation

func create_photo_cutscene_frames() -> Array:
    var frames = []
    var CutscenePlayer = load("res://UI/CutscenePlayer/cutscene_player.tscn").instantiate().get_script()

    frames.append(CutscenePlayer.create_frame(
        "res://Assets/Art/cut-scenes/looking-at-first-scrappng.png",
        ["This photo...it looks familiar..."]
    ))

    return frames

func _on_cutscene_start(cutscene_id: String):
    CutsceneDirector.play_cutscene(cutscene_id)
```

## CutsceneTrigger Properties

- **cutscene_id**: Unique ID for the cutscene to trigger
- **trigger_once**: Only trigger once (default: true)
- **auto_start**: Trigger on level start (default: false)
- **disable_player_control**: Disable player during cutscene (default: true)

## Signals

### CutsceneDirector Signals

- `cutscene_started(cutscene_id)` - Emitted when cutscene begins
- `cutscene_finished(cutscene_id)` - Emitted when cutscene ends
- `cutscene_step_completed(step_index)` - Emitted after each action

### CutsceneTrigger Signals

- `cutscene_triggered(cutscene_id)` - Emitted when player enters trigger

## Tips

1. **Player must be in "player" group**: Ensure your player node is added to the "player" group for CutsceneDirector to find it.

2. **Test in isolation**: Create small test scenes to test individual cutscene sequences before adding to full levels.

3. **Custom actions**: Use `action_custom()` for anything not covered by built-in actions (spawning objects, playing sounds, etc.).

4. **Combine with fullscreen**: You can mix in-level scripted sequences with fullscreen cutscenes for cinematic storytelling.

5. **Control restoration**: Player control is automatically restored when cutscene ends. No need to manually enable it.

## Troubleshooting

**Player not moving during cutscene:**
- Ensure player is in "player" group
- Check that CutsceneDirector found the player (check console)
- Verify target_x position is different from current position

**Cutscene not triggering:**
- Check CutsceneTrigger collision_mask is set to layer 3 (player layer)
- Ensure cutscene is registered before playing
- Check console for error messages

**Player control not restoring:**
- CutsceneDirector automatically calls `enable_control()` when cutscene ends
- If issues persist, manually call `enable_control()` on player controller

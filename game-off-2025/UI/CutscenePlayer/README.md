# CutscenePlayer Component

Full-screen cutscene player for displaying image sequences with dialogue overlay and skip functionality.

## Features

- **Full-screen Image Display**: Shows cutscene images in fullscreen with proper scaling
- **Dialogue Integration**: Uses DialogueManager for text overlay on images
- **Frame Sequencing**: Supports multiple frames with fade transitions
- **Fade Transitions**: Smooth fade in/out between frames (configurable duration)
- **Skip Functionality**: Hold ESC button for 1.5 seconds to skip cutscene
- **Skip Indicator**: Visual progress bar shows skip progress
- **Auto-advance**: Optional automatic frame progression with configurable delays
- **Signals**: Events for started, finished, skipped, and frame changes

## Usage

### Basic Setup

1. **Instance the Scene**: Add `cutscene_player.tscn` to your scene
2. **It's a CanvasLayer**: Renders on layer 99 (above game, below pause menu)
3. **Connect Signals**: Connect to cutscene events in your script

### Example Code

```gdscript
extends Node

@onready var cutscene_player = $CutscenePlayer

func _ready():
    # Connect signals
    cutscene_player.cutscene_finished.connect(_on_cutscene_finished)

    # Start cutscene
    play_opening_cutscene()

func play_opening_cutscene():
    var frames = []

    # Frame 1: Image with dialogue
    frames.append(cutscene_player.create_frame(
        "res://Assets/Art/cut-scenes/sona-close-up-sad.png",
        ["This photo...it looks familiar..."]
    ))

    # Frame 2: Another image
    frames.append(cutscene_player.create_frame(
        "res://Assets/Art/cut-scenes/letter.png",
        [
            "There's writing on the back...",
            "What does it say?"
        ]
    ))

    # Start playing
    cutscene_player.play_cutscene(frames)

func _on_cutscene_finished():
    print("Cutscene done!")
    # Continue to next scene
```

## API Reference

### Methods

#### `play_cutscene(frames: Array) -> void`
Start playing a cutscene sequence.
- `frames`: Array of `CutsceneFrame` objects

#### `skip_cutscene() -> void`
Force skip the current cutscene immediately.

#### `is_cutscene_active() -> bool`
Returns true if a cutscene is currently playing.

#### `get_current_frame_index() -> int`
Returns the index of the current frame being displayed.

#### `get_total_frames() -> int`
Returns the total number of frames in the current cutscene.

#### `static create_frame(image_path: String, dialogue: Array = [], duration: float = 0.0) -> CutsceneFrame`
Static helper to create a cutscene frame.
- `image_path`: Path to the image file (e.g., "res://Assets/Art/cut-scenes/image.png")
- `dialogue`: Array of dialogue strings to display over the image
- `duration`: Auto-advance delay in seconds (0 = manual advance with Space)

### Signals

#### `cutscene_started`
Emitted when a cutscene begins playing.

#### `cutscene_finished`
Emitted when all frames complete or cutscene is skipped.

#### `cutscene_skipped`
Emitted when player skips the cutscene by holding ESC.

#### `frame_changed(frame_index: int)`
Emitted when advancing to a new frame.

### CutsceneFrame Class

```gdscript
class CutsceneFrame:
    var image_path: String          # Path to cutscene image
    var dialogue_lines: Array       # Array of dialogue strings
    var duration: float = 0.0       # Auto-advance time (0 = manual)
```

### Export Variables

Configure these in the Godot Inspector:

- **fade_duration** (float): Seconds for fade transitions between images. Default: 0.5
- **skip_hold_duration** (float): How long to hold ESC to skip. Default: 1.5
- **skip_button** (String): Input action for skipping. Default: "ui_cancel" (ESC)

## Testing

Run `cutscene_player_test.tscn` to test the component:
1. Open the scene in Godot
2. Press F6 to run
3. Press SPACE to start test cutscene
4. Press SPACE to advance through dialogue
5. Hold ESC to test skip functionality

The test displays 3 frames using actual cutscene images from your game.

## Integration Examples

### Opening Cutscene

```gdscript
func play_game_opening():
    var frames = []

    frames.append(cutscene_player.create_frame(
        "res://Assets/Art/cut-scenes/looking-at-first-scrappng.png",
        [
            "This photo...it looks familiar...",
            "I think it's of me and my mom...right before..."
        ]
    ))

    frames.append(cutscene_player.create_frame(
        "res://Assets/Art/cut-scenes/sona-close-up-sad.png",
        ["It kills me to be so alone..."]
    ))

    cutscene_player.play_cutscene(frames)
    await cutscene_player.cutscene_finished

    # Transition to title screen
    SceneManager.load_scene("res://UI/MainMenu.tscn")
```

### Ending Cutscene

```gdscript
func play_game_ending():
    var frames = []

    frames.append(cutscene_player.create_frame(
        "res://Assets/Art/cut-scenes/sona-crying.png",
        [
            "I made it all this way...",
            "...and still cannot reach the top."
        ]
    ))

    frames.append(cutscene_player.create_frame(
        "res://Assets/Art/cut-scenes/letter.png",
        [
            "Wait a minute...",
            "There's writing on the other side..."
        ]
    ))

    cutscene_player.play_cutscene(frames)
    await cutscene_player.cutscene_finished

    # Show credits
```

## How It Works

1. **Frame Sequencing**: Each frame contains an image path and dialogue lines
2. **Image Display**: Images are loaded and displayed with fade transitions
3. **Dialogue Overlay**: DialogueManager handles text display over images
4. **Progression**: Player advances through dialogue, then to next frame
5. **Skip System**: Holding ESC fills progress bar, then skips cutscene

## Notes

- CutscenePlayer requires DialogueManager autoload to be configured
- Images should be placed in `Assets/Art/cut-scenes/` directory
- Uses CanvasLayer 99 (renders above game, below pause menu at layer 100)
- Skip functionality can be disabled by setting `skip_hold_duration` to a very high value
- Fade transitions are configurable per-instance via export variables

## Available Cutscene Images

Your project includes the following cutscene images:
- `letter.png` - The letter/writing on back of photo
- `looking-at-first-scrappng.png` - Sona looking at first photo shard
- `sona-close-up-sad.png` - Close-up of sad Sona
- `sona-crying.png` - Sona crying
- `sona-full-photo-above.png` - Sona with photo above her
- `sona-full-picture.png` - Full picture view
- `sona-seeing-exit.png` - Sona seeing the exit
- `sona-title.png` - Title screen image
